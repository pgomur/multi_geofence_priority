pragma SPARK_Mode (On);

package body Position_Manager with
   Refined_State => (Position_State => Current_Position)
is

   --  Encapsulated current position (initialized to invalid)
   Current_Position : Position_Data := (
      Latitude      => 0.0,
      Longitude     => 0.0,
      Altitude_MSL  => 0.0,
      Velocity      => 0.0,
      Heading       => 0.0,
      UTC_Timestamp => 0,
      GPS_Week      => 0,
      GPS_Seconds   => 0.0,
      Source        => GPS,
      Quality       => Invalid,
      Is_Valid      => False
   );

   --  Overwrites current position state
   procedure Update_Position (Pos : in Position_Data) is
   begin
      Current_Position := Pos;
   end Update_Position;

   --  Returns copy of current position
   function Get_Current_Position return Position_Data is
   begin
      return Current_Position;
   end Get_Current_Position;

   --  Validates position based on quality and validity flags
   function Is_Position_Valid return Boolean is
   begin
      return Current_Position.Is_Valid and then
             Current_Position.Quality /= Invalid;
   end Is_Position_Valid;

end Position_Manager;