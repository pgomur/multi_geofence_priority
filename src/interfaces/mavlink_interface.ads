pragma SPARK_Mode (On);

with Position_Types; use Position_Types;
with MAVLink_Messages; use MAVLink_Messages;

--  MAVLink communication interface
package MAVLink_Interface is

   --  Initialize interface
   procedure Initialize
     with Global => null;
   
   --  Receive vehicle position
   procedure Receive_Position (Pos : out Position_Data; Success : out Boolean)
     with Global => null;
   
   --  Receive heartbeat message
   procedure Receive_Heartbeat (HB : out Heartbeat_Message; Success : out Boolean)
     with Global => null;
   
   --  Send command to vehicle
   procedure Send_Command (Command : in String; Success : out Boolean)
     with Global => null;

end MAVLink_Interface;