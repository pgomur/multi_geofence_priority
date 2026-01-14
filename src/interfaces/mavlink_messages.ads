pragma SPARK_Mode (On);

with Position_Types; use Position_Types;

--  Simulated MAVLink message type definitions
package MAVLink_Messages is

   --  MAVLink message categories
   type Message_Type is (
      HEARTBEAT,
      GLOBAL_POSITION_INT,
      ATTITUDE,
      COMMAND_ACK
   );
   
   --  System operational states
   type System_State is (
      UNINIT,
      BOOT,
      CALIBRATING,
      STANDBY,
      ACTIVE,
      CRITICAL,
      EMERGENCY,
      POWEROFF
   );
   
   --  Flight control modes
   type Flight_Mode is (
      MANUAL,
      STABILIZE,
      GUIDED,
      AUTO,
      LOITER,
      RTL,
      LAND
   );
   
   --  Global position report message
   type Global_Position_Message is record
      Time_Boot_Ms : Natural;
      Latitude     : Latitude_Degrees;
      Longitude    : Longitude_Degrees;
      Altitude_MSL : Altitude_Meters;
      Relative_Alt : Altitude_Meters;
      Vx           : Integer; -- cm/s
      Vy           : Integer; -- cm/s
      Vz           : Integer; -- cm/s
      Heading      : Heading_Degrees;
   end record;
   
   --  System status heartbeat message
   type Heartbeat_Message is record
      Custom_Mode      : Natural;
      System_State_Val : System_State;
      Flight_Mode_Val  : Flight_Mode;
   end record;

end MAVLink_Messages;