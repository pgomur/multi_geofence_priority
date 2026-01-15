pragma SPARK_Mode (On);

with Ada.Numerics.Elementary_Functions;

--  Zone manager implementation with distance calculations
package body Zone_Manager with
   Refined_State => (Zone_State => (Zones, Zone_Count))
is

   --  Zone storage with safe initialization
   Zones : array (1 .. Max_Zones) of Geographic_Zone := (others => (
      ID => 1,
      Zone_Type_Val => Safe_Zone,
      Geometry => Circular,
      Circle => (
         Center_Lat => 0.0,
         Center_Lon => 0.0,
         Radius_Meters => 0.0
      ),
      Vertical => (Floor_MSL => 0.0, Ceiling_MSL => 0.0),
      Priority => 1,
      Is_Active => False,
      Name => (others => ' '),
      Name_Length => 0
   ));
   Zone_Count : Natural range 0 .. Max_Zones := 0;

   --  Earth radius for Haversine formula
   Earth_Radius : constant := 6_371_000.0;

   --  Conversion functions (SPARK_Mode Off for Float operations)
   function To_Float (D : Latitude_Degrees) return Float;
   function To_Float (D : Longitude_Degrees) return Float;
   function Haversine_Distance (
      Lat1, Lon1, Lat2, Lon2 : Float
   ) return Distance_Meters;

   --  Convert latitude to Float
   function To_Float (D : Latitude_Degrees) return Float with SPARK_Mode => Off is
   begin
      return Float(D);
   end To_Float;

   --  Convert longitude to Float
   function To_Float (D : Longitude_Degrees) return Float with SPARK_Mode => Off is
   begin
      return Float(D);
   end To_Float;

   --  Haversine formula for great-circle distance
   function Haversine_Distance (
      Lat1, Lon1, Lat2, Lon2 : Float
   ) return Distance_Meters with SPARK_Mode => Off
   is
      use Ada.Numerics.Elementary_Functions;
      DLat, DLon, A, C : Float;
      Lat1_Rad, Lat2_Rad : Float;
   begin
      Lat1_Rad := Lat1 * Ada.Numerics.Pi / 180.0;
      Lat2_Rad := Lat2 * Ada.Numerics.Pi / 180.0;
      DLat := (Lat2 - Lat1) * Ada.Numerics.Pi / 180.0;
      DLon := (Lon2 - Lon1) * Ada.Numerics.Pi / 180.0;

      A := Sin(DLat / 2.0) * Sin(DLat / 2.0) +
           Cos(Lat1_Rad) * Cos(Lat2_Rad) *
           Sin(DLon / 2.0) * Sin(DLon / 2.0);
      C := 2.0 * Arctan(Sqrt(A), Sqrt(1.0 - A));

      return Distance_Meters(Earth_Radius * C);
   end Haversine_Distance;

   --  Load predefined zones
   procedure Load_Zones is
   begin
      --  No-Fly Zone: (highest priority)
      Zones(1) := (
         ID => 1,
         Zone_Type_Val => No_Fly_Zone,
         Geometry => Circular,
         Circle => (
            Center_Lat => Latitude_Degrees(40.416_775),
            Center_Lon => Longitude_Degrees(-3.703_790),
            Radius_Meters => 5000.0
         ),
         Vertical => (Floor_MSL => 0.0, Ceiling_MSL => 1000.0),
         Priority => 10,
         Is_Active => True,
         Name => "NFZ_DOWNTOWN_AREA                                 ",
         Name_Length => 17
      );

      --  Restricted Area
      Zones(2) := (
         ID => 2,
         Zone_Type_Val => Restricted_Area,
         Geometry => Circular,
         Circle => (
            Center_Lat => Latitude_Degrees(40.450_000),
            Center_Lon => Longitude_Degrees(-3.550_000),
            Radius_Meters => 8000.0
         ),
         Vertical => (Floor_MSL => 0.0, Ceiling_MSL => 3000.0),
         Priority => 9,
         Is_Active => True,
         Name => "RA_MILITARY_BASE                                  ",
         Name_Length => 16
      );

      --  Warning Area
      Zones(3) := (
         ID => 3,
         Zone_Type_Val => Warning_Area,
         Geometry => Circular,
         Circle => (
            Center_Lat => Latitude_Degrees(40.400_000),
            Center_Lon => Longitude_Degrees(-3.650_000),
            Radius_Meters => 12000.0
         ),
         Vertical => (Floor_MSL => 500.0, Ceiling_MSL => 2500.0),
         Priority => 5,
         Is_Active => True,
         Name => "WA_SOUTH_SECTOR                                   ",
         Name_Length => 13
      );

      --  Safe Zone
      Zones(4) := (
         ID => 4,
         Zone_Type_Val => Safe_Zone,
         Geometry => Circular,
         Circle => (
            Center_Lat => Latitude_Degrees(40.380_000),
            Center_Lon => Longitude_Degrees(-3.720_000),
            Radius_Meters => 3000.0
         ),
         Vertical => (Floor_MSL => 0.0, Ceiling_MSL => 500.0),
         Priority => 3,
         Is_Active => True,
         Name => "SZ_LOCAL_AIRFIELD                                 ",
         Name_Length => 17
      );

      --  Mission Area: Operational Sector
      Zones(5) := (
         ID => 5,
         Zone_Type_Val => Mission_Area,
         Geometry => Circular,
         Circle => (
            Center_Lat => Latitude_Degrees(40.420_000),
            Center_Lon => Longitude_Degrees(-3.680_000),
            Radius_Meters => 15000.0
         ),
         Vertical => (Floor_MSL => 200.0, Ceiling_MSL => 4000.0),
         Priority => 2,
         Is_Active => True,
         Name => "OP_OPERATIONAL_SECTOR                             ",
         Name_Length => 21
      );

      Zone_Count := 5;
   end Load_Zones;

   --  Evaluate all active zones against vehicle position
   procedure Evaluate_All_Zones (
      Current_Pos  : in  Position_Data;
      Results      : out Zone_Result_Array;
      Result_Count : out Natural
   ) is
      Dist           : Distance_Meters;
      Inside_Lateral : Boolean;
      Inside_Vertical: Boolean;
   begin
      --  Initialize results array to safe defaults
      Results := (others => (
         Zone_ID => 1,
         Status => Outside,
         Distance_To_Center => 0.0,
         Is_Inside => False,
         Lateral_Check => False,
         Vertical_Check => False
      ));
      
      --  Reset counter
      Result_Count := 0;

      --  Process each zone
      for I in 1 .. Zone_Count loop
         --  SPARK loop invariants
         pragma Loop_Invariant (Result_Count <= I - 1);
         pragma Loop_Invariant (Result_Count <= Max_Zones);
         pragma Loop_Invariant (Zone_Count <= Max_Zones);
         
         if Zones(I).Is_Active then
            Result_Count := Result_Count + 1;

            --  Calculate distance from current position
            Dist := Haversine_Distance(
               To_Float(Current_Pos.Latitude),
               To_Float(Current_Pos.Longitude),
               To_Float(Zones(I).Circle.Center_Lat),
               To_Float(Zones(I).Circle.Center_Lon)
            );

            --  Check lateral containment
            Inside_Lateral := Dist <= Zones(I).Circle.Radius_Meters;
            
            --  Check vertical containment
            Inside_Vertical :=
               Current_Pos.Altitude_MSL >= Zones(I).Vertical.Floor_MSL and then
               Current_Pos.Altitude_MSL <= Zones(I).Vertical.Ceiling_MSL;

            --  Store evaluation result
            Results(Result_Count) := (
               Zone_ID         => Zones(I).ID,
               Status          => (if Inside_Lateral and Inside_Vertical then Inside
                                  elsif Inside_Lateral or Inside_Vertical then Boundary
                                  else Outside),
               Distance_To_Center => Dist,
               Is_Inside       => Inside_Lateral and Inside_Vertical,
               Lateral_Check   => Inside_Lateral,
               Vertical_Check  => Inside_Vertical
            );
         end if;
      end loop;
   end Evaluate_All_Zones;

   --  Get number of loaded zones
   function Get_Zone_Count return Natural is
   begin
      return Zone_Count;
   end Get_Zone_Count;

   --  Retrieve zone by ID (returns first if not found)
   function Get_Zone (ID : Zone_ID) return Geographic_Zone is
   begin
      for I in 1 .. Zone_Count loop
         pragma Loop_Invariant (Zone_Count <= Max_Zones);
         if Zones(I).ID = ID then
            return Zones(I);
         end if;
      end loop;
      return Zones(1);
   end Get_Zone;

end Zone_Manager;