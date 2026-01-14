pragma SPARK_Mode (On);

package Config_Loader is

   --  System-wide configuration parameters
   type System_Config is record
      Vehicle_ID        : String (1 .. 20);
      Vehicle_ID_Length : Natural range 0 .. 20;
      Cycle_Period_Ms   : Positive;     --  Main loop period
      Max_Cycle_Time_Ms : Positive;     --  Execution deadline
      Enable_Logging    : Boolean;      --  Runtime diagnostics
   end record;

   --  Populates Config with default system values
   procedure Load_Config (Config : out System_Config) with
     Global => null;  --  No side effects

end Config_Loader;