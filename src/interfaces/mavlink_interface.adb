pragma SPARK_Mode (Off);

with Ada.Calendar;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Elementary_Functions;

package body MAVLink_Interface is

   Gen : Ada.Numerics.Float_Random.Generator;
   Simulation_Time : Natural := 0;

   --  Base simulation position (Madrid)
   Base_Lat : Float := 40.416_775;
   Base_Lon : Float := -3.703_790;
   Base_Alt : Float := 600.0;

   --  Simulated trajectory parameters
   Trajectory_Angle  : Float := 0.0;
   Trajectory_Radius : Float := 10000.0; --  10 km radius

   procedure Initialize is
   begin
      Ada.Numerics.Float_Random.Reset(Gen);
      Simulation_Time := 0;
   end Initialize;

   --  Generates simulated position with circular movement
   procedure Receive_Position (Pos : out Position_Data; Success : out Boolean) is
      use Ada.Numerics.Elementary_Functions;
      use Ada.Calendar;
      Current_Time : Time := Clock;
      Unix_Time    : Unix_Timestamp;

      --  Variables for circular motion simulation
      Offset_Lat : Float;
      Offset_Lon : Float;
      Noise_Lat  : Float;
      Noise_Lon  : Float;
   begin
      --  Increment simulation time
      Simulation_Time := Simulation_Time + 1000; --  1 second step

      --  Calculate Unix timestamp (from 2020-01-01 epoch)
      Unix_Time := Unix_Timestamp(1_577_836_800 + Simulation_Time / 1000);

      --  Simulate circular movement around base point
      Trajectory_Angle := Trajectory_Angle + 0.01; --  Gradual advance
      if Trajectory_Angle > 2.0 * Ada.Numerics.Pi then
         Trajectory_Angle := 0.0;
      end if;

      --  Calculate position offsets (1° ≈ 111 km)
      Offset_Lat := Cos(Trajectory_Angle) * (Trajectory_Radius / 111_000.0);
      Offset_Lon := Sin(Trajectory_Angle) * (Trajectory_Radius /
                    (111_000.0 * Cos(Base_Lat * Ada.Numerics.Pi / 180.0)));

      --  Add GPS noise (±10 meters)
      Noise_Lat := (Ada.Numerics.Float_Random.Random(Gen) - 0.5) * 0.0001;
      Noise_Lon := (Ada.Numerics.Float_Random.Random(Gen) - 0.5) * 0.0001;

      --  Build position record
      Pos := (
         Latitude      => Latitude_Degrees(Base_Lat + Offset_Lat + Noise_Lat),
         Longitude     => Longitude_Degrees(Base_Lon + Offset_Lon + Noise_Lon),
         Altitude_MSL  => Altitude_Meters(Base_Alt +
                         Ada.Numerics.Float_Random.Random(Gen) * 200.0),
         Velocity      => Velocity_MPS(15.0 +
                         Ada.Numerics.Float_Random.Random(Gen) * 5.0),
         Heading       => Heading_Degrees(Trajectory_Angle * 180.0 / Ada.Numerics.Pi),
         UTC_Timestamp => Unix_Time,
         GPS_Week      => GPS_Week(Unix_Time / 604_800),
         GPS_Seconds   => GPS_Seconds(Float(Unix_Time mod 604_800)),
         Source        => Fused,
         Quality       => (if Ada.Numerics.Float_Random.Random(Gen) > 0.1
                           then Excellent else Good),
         Is_Valid      => True
      );

      Success := True;
   end Receive_Position;

   --  Returns static heartbeat for simulation
   procedure Receive_Heartbeat (HB : out Heartbeat_Message; Success : out Boolean) is
   begin
      HB := (
         Custom_Mode     => 0,
         System_State_Val => ACTIVE,
         Flight_Mode_Val => AUTO
      );
      Success := True;
   end Receive_Heartbeat;

   --  Command transmission stub (always succeeds)
   procedure Send_Command (Command : in String; Success : out Boolean) is
   begin
      --  Simulation: always successful
      Success := True;
   end Send_Command;

end MAVLink_Interface;