pragma SPARK_Mode (On);

with Zone_Types;      use Zone_Types;
with Position_Types;  use Position_Types;
with Zone_Manager;

--  Determines autonomous response actions from zone evaluations
package Action_Handler is

   --  Actions ordered by increasing severity
   type Action_Type is (
      NO_ACTION,
      WARNING,
      ALTITUDE_RESTRICT,
      COURSE_CORRECT,
      RTL,
      EMERGENCY_LAND,
      TERMINATE_FLIGHT
   );

   --  Confidence level for decision validity
   type Confidence_Level is (Low, Medium, High, Critical);

   --  Final immutable decision (thread-safe by design)
   type Decision_Result is record
      Action            : Action_Type;
      ROE_Evaluation    : Boolean;      --  Rules of Engagement applied
      Dispatcher_Active : Boolean;      --  Requires dispatcher execution
      Confidence        : Confidence_Level;
      Reason            : String (1 .. 100);  --  Static length for analysis
      Reason_Length     : Natural range 0 .. 100;
   end record;

   --  Summary of the dominant (highest priority) zone
   type Dominant_Zone_Info is record
      Has_Dominant      : Boolean;
      Zone_ID           : Zone_Types.Zone_ID;
      Priority          : Zone_Types.Zone_Priority;
      Zone_Type_Val     : Zone_Types.Zone_Type;
      Conflict_Detected : Boolean;      --  Multiple zones with same priority
      Discarded_Count   : Natural;      --  Zones discarded during selection
   end record;

   --  Constructor with static size validation
   function Create_Decision (
      Action            : Action_Type;
      ROE_Evaluation    : Boolean;
      Dispatcher_Active : Boolean;
      Confidence        : Confidence_Level;
      Reason            : String
   ) return Decision_Result with
     Global => null,                    --  Side-effect free
     Pre    => Reason'Length <= 100,
     Post   => Create_Decision'Result.Reason_Length = Reason'Length;

   --  Deterministic selection of highest priority zone
   procedure Resolve_Priority (
      Results      : in  Zone_Manager.Zone_Result_Array;
      Result_Count : in  Natural;
      Dominant     : out Dominant_Zone_Info
   ) with
     Global => (Input => Zone_Manager.Zone_State),
     Pre    => Result_Count <= Results'Last,
     Post   => Dominant.Discarded_Count <= Results'Last;

   --  Pure decision logic: no side effects or global state
   procedure Determine_Action (
      Dominant    : in  Dominant_Zone_Info;
      Current_Pos : in  Position_Data;
      Decision    : out Decision_Result
   ) with
     Global => null;

end Action_Handler;