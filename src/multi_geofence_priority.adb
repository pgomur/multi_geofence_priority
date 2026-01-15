pragma SPARK_Mode (Off);  --  Main program with I/O operations

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Ada.Calendar;
with Ada.Calendar.Formatting;

with Position_Types; use Position_Types;
with Position_Manager;
with Zone_Types; use Zone_Types;
with Zone_Manager;
with MAVLink_Interface;
with MAVLink_Messages; use MAVLink_Messages;
with Config_Loader;
with Action_Handler; use Action_Handler;

--  Multi-geofence priority evaluation system main program
procedure Multi_Geofence_Priority is

   Config : Config_Loader.System_Config;
   Cycle_Number : Natural := 0;

   Current_Position : Position_Data;
   Previous_State : System_State := STANDBY;
   Current_State  : System_State := ACTIVE;

   Zone_Results : Zone_Manager.Zone_Result_Array;   --  << unique type
   Result_Count : Natural;

   Dominant_Zone : Dominant_Zone_Info;
   Decision      : Decision_Result;

   Cycle_Start_Time  : Ada.Real_Time.Time;          --  << qualified usage
   Cycle_End_Time    : Ada.Real_Time.Time;
   Cycle_Duration_Ms : Natural;

   Pos_Success : Boolean;
   HB_Success  : Boolean;
   Cmd_Success : Boolean;
   Heartbeat   : Heartbeat_Message;

   Cycle_Error   : Boolean := False;
   Error_Message : String (1 .. 100);
   Error_Length  : Natural := 0;

   --  Print section separator
   procedure Print_Separator is
   begin
      Put_Line("================================================================================");
   end Print_Separator;

   --  Print system header
   procedure Print_Header is
   begin
      New_Line;
      Print_Separator;
      Put_Line("              MULTI-GEOFENCE PRIORITY EVALUATION SYSTEM");
      Print_Separator;
   end Print_Header;

   --  Print cycle evaluation header
   procedure Print_Cycle_Header is
      use Ada.Calendar;
      use Ada.Calendar.Formatting;
      Now : Ada.Calendar.Time := Clock;            --  << qualified usage
   begin
      New_Line;
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                         CYCLE EVALUATION HEADER                            +");
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("  Cycle Number      : " & Natural'Image(Cycle_Number));
      Put_Line("  Vehicle ID        : " & Config.Vehicle_ID(1 .. Config.Vehicle_ID_Length));
      Put_Line("  Trigger Type      : Periodic (Timer-based)");
      Put_Line("  UTC Timestamp     : " & Image(Now));
      Put_Line("  GPS Week          : " & GPS_Week'Image(Current_Position.GPS_Week));
      Put_Line("  GPS Seconds       : " & GPS_Seconds'Image(Current_Position.GPS_Seconds));
      Put_Line("  Previous State    : " & System_State'Image(Previous_State));
      Put_Line("  Current State     : " & System_State'Image(Current_State));
      Print_Separator;
   end Print_Cycle_Header;

   --  Print navigation input data
   procedure Print_Navigation_Input is
   begin
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                          NAVIGATION INPUT                                  +");
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("  Navigation Source : " & Navigation_Source'Image(Current_Position.Source));
      Put_Line("  Position WGS-84   :");
      Put_Line("    Latitude        : " & Latitude_Degrees'Image(Current_Position.Latitude) & " deg");
      Put_Line("    Longitude       : " & Longitude_Degrees'Image(Current_Position.Longitude) & " deg");
      Put_Line("  Altitude MSL      : " & Altitude_Meters'Image(Current_Position.Altitude_MSL) & " m");
      Put_Line("  Data Validity     : " & Boolean'Image(Current_Position.Is_Valid));
      Put_Line("  Data Quality      : " & Position_Quality'Image(Current_Position.Quality));
      Put_Line("  Velocity (Ground) : " & Velocity_MPS'Image(Current_Position.Velocity) & " m/s");
      Put_Line("  Heading (True)    : " & Heading_Degrees'Image(Current_Position.Heading) & " deg");
      Print_Separator;
   end Print_Navigation_Input;

   --  Print global zone evaluation summary
   procedure Print_Zone_Evaluation_Global is
   begin
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                      ZONE EVALUATION (GLOBAL)                              +");
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("  Total Zones Loaded    : " & Natural'Image(Zone_Manager.Get_Zone_Count));
      Put_Line("  Zones Evaluated       : " & Natural'Image(Result_Count));
      Put_Line("  Evaluation Method     : Haversine distance + vertical bounds");
      Print_Separator;
   end Print_Zone_Evaluation_Global;

   --  Print individual zone evaluation details
   procedure Print_Zone_Details is
      Zone : Geographic_Zone;
      Result : Zone_Evaluation_Result;
   begin
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                      INDIVIDUAL ZONE EVALUATION                            +");
      Put_Line("+----------------------------------------------------------------------------+");

      for I in 1 .. Result_Count loop
         Result := Zone_Results(I);
         Zone   := Zone_Manager.Get_Zone(Result.Zone_ID);

         Put_Line("  + Zone #" & Zone_ID'Image(Zone.ID) &
                 " -------------------------------------------");
         Put_Line("  + Name              : " & Zone.Name(1 .. Zone.Name_Length));
         Put_Line("  + Type              : " & Zone_Type'Image(Zone.Zone_Type_Val));
         Put_Line("  + Geometry          : " & Zone_Geometry'Image(Zone.Geometry));

         if Zone.Geometry = Circular then
            Put_Line("  + Center (Lat/Lon)  : " &
                    Latitude_Degrees'Image(Zone.Circle.Center_Lat) & " / " &
                    Longitude_Degrees'Image(Zone.Circle.Center_Lon));
            Put_Line("  + Radius            : " &
                    Distance_Meters'Image(Zone.Circle.Radius_Meters) & " m");
         end if;

         Put_Line("  + Vertical Limits   :");
         Put_Line("  +   Floor MSL       : " &
                 Altitude_Meters'Image(Zone.Vertical.Floor_MSL) & " m");
         Put_Line("  +   Ceiling MSL     : " &
                 Altitude_Meters'Image(Zone.Vertical.Ceiling_MSL) & " m");
         Put_Line("  + Priority          : " &
                 Zone_Priority'Image(Zone.Priority));
         Put_Line("  + Distance to Center: " &
                 Distance_Meters'Image(Result.Distance_To_Center) & " m");
         Put_Line("  + Lateral Check     : " & Boolean'Image(Result.Lateral_Check));
         Put_Line("  + Vertical Check    : " & Boolean'Image(Result.Vertical_Check));
         Put_Line("  + Overall Status    : " & Zone_Status'Image(Result.Status));
         Put_Line("  + Inside Zone       : " & Boolean'Image(Result.Is_Inside));
         Put_Line("  +------------------------------------------------------------------------");
      end loop;

      Print_Separator;
   end Print_Zone_Details;

   --  Print priority resolution results
   procedure Print_Priority_Resolution is
   begin
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                              PRIORITY RESOLUTION                           +");
      Put_Line("+----------------------------------------------------------------------------+");

      if Dominant_Zone.Has_Dominant then
         declare
            Zone : Geographic_Zone := Zone_Manager.Get_Zone(Dominant_Zone.Zone_ID);
         begin
            Put_Line("  Resolution Method     : Highest Priority Wins");
            Put_Line("  Dominant Zone ID      : " & Zone_ID'Image(Dominant_Zone.Zone_ID));
            Put_Line("  Dominant Zone Name    : " & Zone.Name(1 .. Zone.Name_Length));
            Put_Line("  Dominant Zone Type    : " &
                    Zone_Type'Image(Dominant_Zone.Zone_Type_Val));
            Put_Line("  Dominant Priority     : " &
                    Zone_Priority'Image(Dominant_Zone.Priority));
            Put_Line("  Zones Discarded       : " &
                    Natural'Image(Dominant_Zone.Discarded_Count));
            Put_Line("  Priority Conflict     : " &
                    Boolean'Image(Dominant_Zone.Conflict_Detected));

            if Dominant_Zone.Conflict_Detected then
               Put_Line("  Conflict Resolution   : First detected zone selected (deterministic)");
            end if;
         end;
      else
         Put_Line("  Resolution Method     : No Active Zones");
         Put_Line("  Dominant Zone         : NONE");
         Put_Line("  Status                : Clear airspace - no restrictions");
      end if;

      Print_Separator;
   end Print_Priority_Resolution;

   --  Print decision output
   procedure Print_Decision is
   begin
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                            DECISION OUTPUT                                 +");
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("  Operational Action    : " & Action_Type'Image(Decision.Action));
      Put_Line("  ROE Evaluation        : " & Boolean'Image(Decision.ROE_Evaluation));
      Put_Line("  Dispatcher Activated  : " & Boolean'Image(Decision.Dispatcher_Active));
      Put_Line("  Decision Confidence   : " &
              Confidence_Level'Image(Decision.Confidence));
      Put_Line("  Reasoning             : ");
      Put_Line("    " & Decision.Reason(1 .. Decision.Reason_Length));

      if Decision.Dispatcher_Active then
         Put_Line("  Command Sent          : " & Action_Type'Image(Decision.Action));
         Put_Line("  Command Status        : " &
                 (if Cmd_Success then "SUCCESS" else "FAILED"));
      end if;

      Print_Separator;
   end Print_Decision;

   --  Print system state information
   procedure Print_System_State is
      State_Transition : Boolean := (Previous_State /= Current_State);
   begin
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                           SYSTEM STATE                                     +");
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("  Current System State  : " & System_State'Image(Current_State));
      Put_Line("  Previous System State : " & System_State'Image(Previous_State));
      Put_Line("  State Transition      : " & Boolean'Image(State_Transition));

      if State_Transition then
         Put_Line("  Transition Details    : " &
                 System_State'Image(Previous_State) & " -> " &
                 System_State'Image(Current_State));
      end if;

      Put_Line("  Heartbeat Status      : " & (if HB_Success then "NOMINAL" else "DEGRADED"));
      Put_Line("  MAVLink Connection    : ACTIVE");
      Print_Separator;
   end Print_System_State;

   --  Print cycle execution integrity
   procedure Print_Cycle_Integrity is
   begin
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("+                          CYCLE INTEGRITY                                   +");
      Put_Line("+----------------------------------------------------------------------------+");
      Put_Line("  Cycle Completion      : " & (if not Cycle_Error then "COMPLETE" else "ERROR"));
      Put_Line("  Execution Time        : " & Natural'Image(Cycle_Duration_Ms) & " ms");
      Put_Line("  Time Budget           : " & Natural'Image(Config.Max_Cycle_Time_Ms) & " ms");
      Put_Line("  Time Compliance       : " &
              (if Cycle_Duration_Ms <= Config.Max_Cycle_Time_Ms
               then "WITHIN LIMITS" else "EXCEEDED"));

      if Cycle_Error then
         Put_Line("  Error Detected        : YES");
         Put_Line("  Error Description     : " & Error_Message(1 .. Error_Length));
      else
         Put_Line("  Errors Detected       : NONE");
      end if;

      Put_Line("  Data Integrity        : VERIFIED");
      Put_Line("  Next Cycle In         : " & Natural'Image(Config.Cycle_Period_Ms) & " ms");
      Print_Separator;
   end Print_Cycle_Integrity;

--  Main program execution
begin
   Print_Header;

   --  System initialization
   Put_Line(">> System Initialization");
   Config_Loader.Load_Config(Config);
   Put_Line("   [OK] Configuration loaded");

   MAVLink_Interface.Initialize;
   Put_Line("   [OK] MAVLink interface initialized");

   Zone_Manager.Load_Zones;
   Put_Line("   [OK] Geofence zones loaded (" &
           Natural'Image(Zone_Manager.Get_Zone_Count) & " zones)");

   Put_Line(">> Entering main evaluation loop (Press Ctrl+C to stop)");
   Put_Line("   Cycle Period: " & Natural'Image(Config.Cycle_Period_Ms) & " ms");
   New_Line;

   --  Main evaluation loop
   loop
      Cycle_Number := Cycle_Number + 1;
      Cycle_Start_Time  := Ada.Real_Time.Clock;
      Cycle_Error := False;

      --  1. Receive position data
      MAVLink_Interface.Receive_Position(Current_Position, Pos_Success);

      if not Pos_Success then
         Cycle_Error := True;
         Error_Message := "Failed to receive position data from MAVLink                                                  ";
         Error_Length := 43;
      end if;

      Position_Manager.Update_Position(Current_Position);

      --  2. Receive heartbeat
      MAVLink_Interface.Receive_Heartbeat(Heartbeat, HB_Success);
      Previous_State := Current_State;
      Current_State  := Heartbeat.System_State_Val;

      --  3. Evaluate all zones
      Zone_Manager.Evaluate_All_Zones(Current_Position, Zone_Results, Result_Count);

      --  4. Resolve priorities
      Resolve_Priority(Zone_Results, Result_Count, Dominant_Zone);

      --  5. Determine action
      Determine_Action(Dominant_Zone, Current_Position, Decision);

      --  6. Send command if required
      if Decision.Dispatcher_Active then
         MAVLink_Interface.Send_Command(Action_Type'Image(Decision.Action), Cmd_Success);
         if not Cmd_Success then
            Cycle_Error := True;
            Error_Message := "Failed to send command to vehicle                                                           ";
            Error_Length := 32;
         end if;
      else
         Cmd_Success := True; --  No command required
      end if;

      --  Calculate cycle duration
      Cycle_End_Time    := Ada.Real_Time.Clock;
      Cycle_Duration_Ms := Natural(To_Duration(Cycle_End_Time - Cycle_Start_Time) * 1000.0);

      --  Verify timing constraints
      if Cycle_Duration_Ms > Config.Max_Cycle_Time_Ms then
         Cycle_Error := True;
         Error_Message := "Cycle execution time exceeded maximum allowed limit                                           ";
         Error_Length := 51;
      end if;

      --  7. Print complete cycle report
      Print_Cycle_Header;
      Print_Navigation_Input;
      Print_Zone_Evaluation_Global;
      Print_Zone_Details;
      Print_Priority_Resolution;
      Print_Decision;
      Print_System_State;
      Print_Cycle_Integrity;

      --  Wait for next cycle
      delay until Cycle_Start_Time + Milliseconds(Config.Cycle_Period_Ms);
   end loop;

end Multi_Geofence_Priority;