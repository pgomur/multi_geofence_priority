pragma SPARK_Mode (On);

with Position_Types; use Position_Types;

--  Position state management interface
package Position_Manager with
   Abstract_State => Position_State,
   Initializes => Position_State
is

   --  Updates current position state
   procedure Update_Position (Pos : in Position_Data) with
     Global => (Output => Position_State);
   
   --  Returns current position
   function Get_Current_Position return Position_Data with
     Global => (Input => Position_State);
   
   --  Validates current position quality
   function Is_Position_Valid return Boolean with
     Global => (Input => Position_State);

end Position_Manager;