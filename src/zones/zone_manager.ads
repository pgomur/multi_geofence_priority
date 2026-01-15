pragma SPARK_Mode (On);
with Zone_Types; use Zone_Types;
with Position_Types; use Position_Types;

--  Zone management and evaluation interface
package Zone_Manager with
   Abstract_State => Zone_State
is
   --  Array for storing zone evaluation results
   type Zone_Result_Array is array (1 .. Max_Zones) of Zone_Evaluation_Result;
   
   --  Load zone definitions into system state
   procedure Load_Zones with
     Global => (In_Out => Zone_State),
     Post => Get_Zone_Count <= Max_Zones;
   
   --  Evaluate all zones against current position
   procedure Evaluate_All_Zones (
      Current_Pos  : in  Position_Data;
      Results      : out Zone_Result_Array;
      Result_Count : out Natural
   ) with 
     Global => (Input => Zone_State),
     Pre => Get_Zone_Count <= Max_Zones;
   
   --  Get total number of loaded zones
   function Get_Zone_Count return Natural with
     Global => (Input => Zone_State),
     Post => Get_Zone_Count'Result <= Max_Zones;
   
   --  Retrieve zone by identifier
   function Get_Zone (ID : Zone_ID) return Geographic_Zone with
     Global => (Input => Zone_State),
     Pre => Get_Zone_Count <= Max_Zones;
     
end Zone_Manager;