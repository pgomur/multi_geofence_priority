pragma SPARK_Mode (On);

with Zone_Manager;

--  Implements decision logic with deterministic priority resolution
package body Action_Handler is

   --  Complete initialization required for SPARK proof of array assignment
   function Create_Decision (
      Action            : Action_Type;
      ROE_Evaluation    : Boolean;
      Dispatcher_Active : Boolean;
      Confidence        : Confidence_Level;
      Reason            : String
   ) return Decision_Result is
      Result : Decision_Result := (
         Action            => Action,
         ROE_Evaluation    => ROE_Evaluation,
         Dispatcher_Active => Dispatcher_Active,
         Confidence        => Confidence,
         Reason            => (others => ' '),  --  Padding ensures full initialization
         Reason_Length     => 0
      );
   begin
      --  Overlay actual data on padded array
      Result.Reason (1 .. Reason'Length) := Reason;
      Result.Reason_Length := Reason'Length;
      return Result;
   end Create_Decision;

   --  Single-pass deterministic selection of highest priority zone
   --  O(n) complexity with conflict detection for equal priorities
   procedure Resolve_Priority (
      Results      : in  Zone_Manager.Zone_Result_Array;
      Result_Count : in  Natural;
      Dominant     : out Dominant_Zone_Info
   ) is
      Max_Priority : Zone_Priority := Zone_Priority'First;
      Dominant_ID  : Zone_ID       := Zone_ID'First;
      Found        : Boolean       := False;
      Discarded    : Natural       := 0;
      Conflict     : Boolean       := False;
      Current_Zone : Geographic_Zone;
   begin
      for I in Results'Range loop
         exit when I > Result_Count;
         
         --  Discarded count cannot exceed processed elements
         pragma Loop_Invariant (Discarded <= I - Results'First);
         
         if Results(I).Is_Inside then
            Current_Zone := Zone_Manager.Get_Zone(Results(I).Zone_ID);
            
            --  Update dominant zone on higher priority
            if Current_Zone.Priority > Max_Priority then
               Max_Priority := Current_Zone.Priority;
               Dominant_ID  := Results(I).Zone_ID;
               Found        := True;
               Conflict     := False;
            --  Mark conflict when equal priorities collide
            elsif Current_Zone.Priority = Max_Priority then
               if Found then
                  Conflict := True;  --  ROE required to resolve tie
               else
                  --  First element at this priority level
                  Max_Priority := Current_Zone.Priority;
                  Dominant_ID  := Results(I).Zone_ID;
                  Found        := True;
               end if;
            else
               Discarded := Discarded + 1;
            end if;
         end if;
      end loop;

      if Found then
         Current_Zone := Zone_Manager.Get_Zone(Dominant_ID);
         Dominant := (
            Has_Dominant      => True,
            Zone_ID           => Dominant_ID,
            Priority          => Max_Priority,
            Zone_Type_Val     => Current_Zone.Zone_Type_Val,
            Conflict_Detected => Conflict,
            Discarded_Count   => Discarded
         );
      else
         --  Safe neutral values when no zones active
         Dominant := (
            Has_Dominant      => False,
            Zone_ID           => Zone_ID'First,
            Priority          => Zone_Priority'First,
            Zone_Type_Val     => Safe_Zone,
            Conflict_Detected => False,
            Discarded_Count   => 0
         );
      end if;
   end Resolve_Priority;

   --  Maps dominant zone type to required action (lowest severity)
   procedure Determine_Action (
      Dominant    : in  Dominant_Zone_Info;
      Current_Pos : in  Position_Data;
      Decision    : out Decision_Result
   ) is
      pragma Unreferenced (Current_Pos);  --  Position used in future extensions
   begin
      if not Dominant.Has_Dominant then
         Decision := Create_Decision (
            Action            => NO_ACTION,
            ROE_Evaluation    => True,
            Dispatcher_Active => False,
            Confidence        => High,
            Reason            => "No active zones - normal operations"
         );
         return;
      end if;

      --  Action severity correlates with zone restriction level
      case Dominant.Zone_Type_Val is
         when No_Fly_Zone =>
            --  Emergency override of ROE for critical violations
            if Dominant.Priority >= 9 then
               Decision := Create_Decision (
                  Action            => EMERGENCY_LAND,
                  ROE_Evaluation    => False,  --  Immediate action required
                  Dispatcher_Active => True,
                  Confidence        => Critical,
                  Reason            => "NFZ violation - priority >= 9 - immediate landing required"
               );
            else
               Decision := Create_Decision (
                  Action            => RTL,
                  ROE_Evaluation    => False,
                  Dispatcher_Active => True,
                  Confidence        => High,
                  Reason            => "NFZ violation - return to launch"
               );
            end if;

         when Restricted_Area =>
            Decision := Create_Decision (
               Action            => COURSE_CORRECT,
               ROE_Evaluation    => True,   --  ROE permits correction
               Dispatcher_Active => True,
               Confidence        => High,
               Reason            => "RA penetration - course correction required"
            );

         when Warning_Area =>
            Decision := Create_Decision (
               Action            => WARNING,
               ROE_Evaluation    => True,
               Dispatcher_Active => True,
               Confidence        => Medium, --  Lower confidence for advisory
               Reason            => "WA entered - operator notified"
            );

         when Safe_Zone =>
            Decision := Create_Decision (
               Action            => NO_ACTION,
               ROE_Evaluation    => True,
               Dispatcher_Active => False,
               Confidence        => High,
               Reason            => "Within safe zone - operations normal"
            );

         when Mission_Area =>
            Decision := Create_Decision (
               Action            => NO_ACTION,
               ROE_Evaluation    => True,
               Dispatcher_Active => False,
               Confidence        => High,
               Reason            => "Within mission area - operations authorized"
            );
      end case;
   end Determine_Action;

end Action_Handler;