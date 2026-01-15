pragma SPARK_Mode (On);

package Position_Types is

   --  WGS-84 coordinate types
   type Latitude_Degrees  is delta 0.000_000_01 range -90.0 .. 90.0;
   type Longitude_Degrees is delta 0.000_000_01 range -180.0 .. 180.0;
   type Altitude_Meters   is delta 0.01 range -1000.0 .. 50_000.0;

   --  Speed in meters per second
   type Velocity_MPS is delta 0.01 range 0.0 .. 500.0;

   --  Heading in degrees (0-360)
   type Heading_Degrees is delta 0.01 range 0.0 .. 360.0;

   --  Unix timestamp (seconds since 1970-01-01)
   type Unix_Timestamp is range 0 .. 2**63 - 1;

   --  GPS timestamp (weeks + seconds)
   type GPS_Week   is range 0 .. 65_535;
   type GPS_Seconds is delta 0.001 range 0.0 .. 604_800.0;

   --  Position quality indicator
   type Position_Quality is (Invalid, Poor, Fair, Good, Excellent);

   --  Navigation source type
   type Navigation_Source is (GPS, GLONASS, Galileo, BeiDou, INS, Fused);

   --  Complete position structure
   type Position_Data is record
      Latitude      : Latitude_Degrees;
      Longitude     : Longitude_Degrees;
      Altitude_MSL  : Altitude_Meters;
      Velocity      : Velocity_MPS;
      Heading       : Heading_Degrees;
      UTC_Timestamp : Unix_Timestamp;
      GPS_Week      : Position_Types.GPS_Week;   -- << explicit qualification
      GPS_Seconds   : Position_Types.GPS_Seconds;
      Source        : Navigation_Source;
      Quality       : Position_Quality;
      Is_Valid      : Boolean;
   end record;

end Position_Types;