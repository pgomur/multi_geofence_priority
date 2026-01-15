pragma SPARK_Mode (On);

with Position_Types; use Position_Types;

--  Zone definition and evaluation types
package Zone_Types is

   --  Geometric shape definitions
   type Zone_Geometry is (Circular, Polygonal, Corridor);

   --  Priority levels (1 = lowest, 10 = highest)
   type Zone_Priority is range 1 .. 10;

   --  Zone entry status
   type Zone_Status is (Outside, Inside, Boundary);

   --  Zone classification types
   type Zone_Type is (
      No_Fly_Zone,      --  NFZ: Prohibited airspace
      Restricted_Area,  --  RA: Authorization required
      Warning_Area,     --  WA: Advisory only
      Safe_Zone,        --  SZ: Normal operations
      Mission_Area      --  MA: Mission zone
   );

   --  Distance measurements in meters
   type Distance_Meters is delta 0.01 range 0.0 .. 1_000_000.0;

   --  Unique zone identifier
   type Zone_ID is range 1 .. 1000;

   --  Maximum supported zones
   Max_Zones : constant := 100;

   --  Circular zone definition (center + radius)
   type Circular_Zone is record
      Center_Lat    : Latitude_Degrees;
      Center_Lon    : Longitude_Degrees;
      Radius_Meters : Distance_Meters;
   end record;

   --  Vertical altitude limits
   type Vertical_Limits is record
      Floor_MSL   : Altitude_Meters;   --  Minimum altitude
      Ceiling_MSL : Altitude_Meters;   --  Maximum altitude
   end record;

   --  Complete zone definition record
   type Geographic_Zone is record
      ID            : Zone_Types.Zone_ID;   --  << explicit qualification
      Zone_Type_Val : Zone_Type;
      Geometry      : Zone_Geometry;
      Circle        : Circular_Zone;        --  Valid only if Geometry = Circular
      Vertical      : Vertical_Limits;
      Priority      : Zone_Priority;
      Is_Active     : Boolean;
      Name          : String (1 .. 50);
      Name_Length   : Natural range 0 .. 50;
   end record;

   --  Single zone evaluation result
   type Zone_Evaluation_Result is record
      Zone_ID         : Zone_Types.Zone_ID;   --  << explicit qualification
      Status          : Zone_Status;
      Distance_To_Center : Distance_Meters;   --  From zone center
      Is_Inside       : Boolean;
      Lateral_Check   : Boolean;              --  2D containment
      Vertical_Check  : Boolean;              --  Altitude containment
   end record;

end Zone_Types;