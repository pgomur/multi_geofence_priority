pragma SPARK_Mode (Off);

package body Config_Loader is

   --  Load default system configuration parameters
   procedure Load_Config (Config : out System_Config) is
   begin
      Config := (
         Vehicle_ID => "UAV_ALPHA_001       ",
         Vehicle_ID_Length => 13,
         Cycle_Period_Ms => 1000,      --  1 Hz main loop
         Max_Cycle_Time_Ms => 950,     --  Safety margin (95% of period)
         Enable_Logging => True        --  Runtime diagnostics enabled
      );
   end Load_Config;

end Config_Loader;