# Multi-Geofence Priority System

Functional prototype with a formally verified core using Ada/SPARK, applying DO-178C principles and STANAG 4586-based priority logic for multi-zone geofencing systems in UAVs.

<p>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-0078D7?logo=github&logoColor=white" />
  </a>
  <img src="https://img.shields.io/badge/Ada-2022-5A9BD5?style=flat&logo=ada&logoColor=white" />
  <img src="https://img.shields.io/badge/SPARK-FSF_15.0-1F3A93?style=flat&logo=ada&logoColor=white" />
  <img src="https://img.shields.io/badge/GNAT-15.2.1-FF7F11?style=flat&logo=gnu&logoColor=white" />
  <img src="https://img.shields.io/badge/Alire-2.1.0-28A745?style=flat" />
</p>

## Table of Contents
- [Building and Running](#building-and-running)
- [System Output Explained](#live-system-output)
- [Formal Verification Results](#verification-results)

## Building and Running
### Step 1: Build

```bash
alr build
```
### Step 2: Execute and See Live Output
```bash
./bin/multi_geofence_priority
```
### Step 3: Run Formal Verification

```bash
alr exec -- gnatprove -P multi_geofence_priority.gpr --report=all

# View detailed proof results
type obj\gnatprove\gnatprove.out
```

## Live System Output

```
================================================================================
           MULTI-GEOFENCE PRIORITY EVALUATION SYSTEM Compliance Mode
================================================================================
>> System Initialization
   [OK] Configuration loaded
   [OK] MAVLink interface initialized
   [OK] Geofence zones loaded ( 5 zones)           # Number of geographic zones loaded into memory
->> Entering main evaluation loop (Press Ctrl+C to stop)
   Cycle Period:  1000 ms                          # Fixed interval between cycles (periodicity)


+----------------------------------------------------------------------------+
+                         CYCLE EVALUATION HEADER                            +
+----------------------------------------------------------------------------+
  Cycle Number      :  1                          # Current iteration of main loop
  Vehicle ID        : UAV_ALPHA_001               # Unique vehicle identifier
  Trigger Type      : Periodic (Timer-based)      # Event triggering evaluation
  UTC Timestamp     : 2026-01-15 17:59:03         # System date/time for logging
  GPS Week          :  2608                       # GPS week (rollover every 1024 weeks)
  GPS Seconds       :  518401.000                 # Seconds within GPS week
  Previous State    : ACTIVE                      # MAVLink state in previous cycle
  Current State     : ACTIVE                      # Current MAVLink state (STANDBY/ACTIVE/EMERGENCY)
================================================================================
+----------------------------------------------------------------------------+
+                          NAVIGATION INPUT                                  +
+----------------------------------------------------------------------------+
  Navigation Source : FUSED                       # Data source: GPS/GLONASS/INS combined
  Position WGS-84   :                             # Coordinates in WGS-84 system
    Latitude        :  40.50685501 deg            # Latitude of current position
    Longitude       : -3.70261502 deg             # Longitude of current position
  Altitude MSL      :  786.89 m                   # Altitude above mean sea level (meters)
  Data Validity     : TRUE                        # Position data integrity flag
  Data Quality      : EXCELLENT                   # Signal quality (Invalid/Poor/Fair/Good/Excellent)
  Velocity (Ground) :  17.68 m/s                  # Ground speed (m/s)
  Heading (True)    :  0.57 deg                   # True heading (0-360 degrees)
================================================================================
+----------------------------------------------------------------------------+
+                      ZONE EVALUATION (GLOBAL)                              +
+----------------------------------------------------------------------------+
  Total Zones Loaded    :  5                      # Zones loaded from configuration
  Zones Evaluated       :  5                      # Zones processed this cycle (active)
  Evaluation Method     : Haversine distance + vertical bounds  # Calculation algorithm
================================================================================
+----------------------------------------------------------------------------+
+                      INDIVIDUAL ZONE EVALUATION                            +
+----------------------------------------------------------------------------+
  + Zone # 1 -------------------------------------------
  + Name              : NFZ_DOWNTOWN_AREA         # Human-readable zone description
  + Type              : NO_FLY_ZONE               # Category NFZ/RA/WA/SZ/MA
  + Geometry          : CIRCULAR                  # Current geometric shape
  + Center (Lat/Lon)  :  40.41677500 / -3.70378999  # Center coordinates
  + Radius            :  5000.00 m                # Circular zone radius (meters)
  + Vertical Limits   :                           # Vertical altitude limits
  +   Floor MSL       :  0.00 m                   # Minimum altitude (meters)
  +   Ceiling MSL     :  1000.00 m                # Maximum altitude (meters)
  + Priority          :  10                       # STANAG priority value (1-10)
  + Distance to Center:  10016.96 m               # UAV-to-center distance (meters)
  + Lateral Check     : FALSE                     # TRUE if distance < radius
  + Vertical Check    : TRUE                      # TRUE if altitude within limits
  + Overall Status    : BOUNDARY                  # Combined state (Inside/Outside/Boundary)
  + Inside Zone       : FALSE                     # TRUE if lateral AND vertical are TRUE
  +------------------------------------------------------------------------
  + Zone # 2 -------------------------------------------
  + Name              : RA_MILITARY_BASE
  + Type              : RESTRICTED_AREA
  + Geometry          : CIRCULAR
  + Center (Lat/Lon)  :  40.45000000 / -3.55000000
  + Radius            :  8000.00 m
  + Vertical Limits   :
  +   Floor MSL       :  0.00 m
  +   Ceiling MSL     :  3000.00 m
  + Priority          :  9
  + Distance to Center:  14373.22 m
  + Lateral Check     : FALSE
  + Vertical Check    : TRUE
  + Overall Status    : BOUNDARY
  + Inside Zone       : FALSE
  +------------------------------------------------------------------------
  + Zone # 3 -------------------------------------------
  + Name              : WA_SOUTH_SECT
  + Type              : WARNING_AREA
  + Geometry          : CIRCULAR
  + Center (Lat/Lon)  :  40.40000000 / -3.65000000
  + Radius            :  12000.00 m
  + Vertical Limits   :
  +   Floor MSL       :  500.00 m
  +   Ceiling MSL     :  2500.00 m
  + Priority          :  5
  + Distance to Center:  12688.20 m
  + Lateral Check     : FALSE
  + Vertical Check    : TRUE
  + Overall Status    : BOUNDARY
  + Inside Zone       : FALSE
  +------------------------------------------------------------------------
  + Zone # 4 -------------------------------------------
  + Name              : SZ_LOCAL_AIRFIELD
  + Type              : SAFE_ZONE
  + Geometry          : CIRCULAR
  + Center (Lat/Lon)  :  40.38000000 / -3.72000000
  + Radius            :  3000.00 m
  + Vertical Limits   :
  +   Floor MSL       :  0.00 m
  +   Ceiling MSL     :  500.00 m
  + Priority          :  3
  + Distance to Center:  14182.02 m
  + Lateral Check     : FALSE
  + Vertical Check    : FALSE
  + Overall Status    : OUTSIDE
  + Inside Zone       : FALSE
  +------------------------------------------------------------------------
  + Zone # 5 -------------------------------------------
  + Name              : OP_OPERATIONAL_SECTOR
  + Type              : MISSION_AREA
  + Geometry          : CIRCULAR
  + Center (Lat/Lon)  :  40.41999999 / -3.68000000
  + Radius            :  15000.00 m
  + Vertical Limits   :
  +   Floor MSL       :  200.00 m
  +   Ceiling MSL     :  4000.00 m
  + Priority          :  2
  + Distance to Center:  9845.71 m
  + Lateral Check     : TRUE
  + Vertical Check    : TRUE
  + Overall Status    : INSIDE
  + Inside Zone       : TRUE
  +------------------------------------------------------------------------
================================================================================
+----------------------------------------------------------------------------+
+                              PRIORITY RESOLUTION                           +
+----------------------------------------------------------------------------+
  Resolution Method     : Highest Priority Wins   # STANAG resolution algorithm
  Dominant Zone ID      :  5                      # Winning zone by priority
  Dominant Zone Name    : OP_OPERATIONAL_SECTOR   # Dominant zone name
  Dominant Zone Type    : MISSION_AREA            # Dominant zone type
  Dominant Priority     :  2                      # Winning priority value
  Zones Discarded       :  0                      # Zones discarded by lower priority
  Priority Conflict     : FALSE                   # TRUE if multiple zones share max priority
================================================================================
+----------------------------------------------------------------------------+
+                            DECISION OUTPUT                                 +
+----------------------------------------------------------------------------+
  Operational Action    : NO_ACTION               # Final system action (WARNING/RTL/EMERGENCY_LAND)
  ROE Evaluation        : TRUE                    # Rules of Engagement evaluated
  Dispatcher Activated  : FALSE                   # TRUE if command sent to vehicle
  Decision Confidence   : HIGH                    # Confidence level in decision (Low/Medium/High/Critical)
  Reasoning             : 
    Within mission area - operations authorized
================================================================================
+----------------------------------------------------------------------------+
+                           SYSTEM STATE                                     +
+----------------------------------------------------------------------------+
  Current System State  : ACTIVE                  # Current MAVLink state (STANDBY/ACTIVE/EMERGENCY)
  Previous System State : ACTIVE                  # State in previous cycle
  State Transition      : FALSE                   # TRUE if state changed
  Heartbeat Status      : NOMINAL                 # MAVLink communication state (NOMINAL/DEGRADED)
  MAVLink Connection    : ACTIVE                  # Data link state
================================================================================
+----------------------------------------------------------------------------+
+                          CYCLE INTEGRITY                                   +
+----------------------------------------------------------------------------+
  Cycle Completion      : COMPLETE                # Cycle success/failure flag
  Execution Time        :  0 ms                   # Cycle processing time
  Time Budget           :  950 ms                 # Maximum allowed time limit
  Time Compliance       : WITHIN LIMITS           # Time vs budget comparison result
  Errors Detected       : NONE                    # TRUE if cycle error occurred
  Data Integrity        : VERIFIED                # Data integrity flag (always VERIFIED if no error)
  Next Cycle In         :  1000 ms                # Time until next cycle
================================================================================
```
> ⚠️ **System in continuous loop - more cycles available (Ctrl+C to stop)**

### Verification Results
```
SPARK Analysis Results        Total    Flow    Provers    Justified    Unproved
─────────────────────────────────────────────────────────────────────────────────
Data Dependencies               10      10         -           -           -
Flow Dependencies                1       1         -           -           -
Initialization                   9       9         -           -           -
Run-time Checks                 13       -        13           -           -
Assertions                      10       -        10           -           -
Functional Contracts            13       -        13           -           -
Termination                      5       5         -           -           -
─────────────────────────────────────────────────────────────────────────────────
Total                           61   25 (41%)  36 (59%)        0           0
```

### Verification Status: ✅ **100% of Verifiable Code Proven**

- **0 errors** in verification for code with `SPARK_Mode (On)`
- **0 unproved checks** in verifiable modules
- **61 total checks** verified automatically
- **Modules with Islets**: 2 mathematical functions (justified)

### SPARK-Verified Modules

| Module | Verified Subprograms | Flow Analysis | Proof |
|--------|---------------------------|---------------|-------|
| `Action_Handler` | 4/4 | ✅ | ✅ 24 checks |
| `Position_Manager` | 4/4 | ✅ | ✅ 4 checks |
| `Zone_Manager` | **5/8** | ⚠️ Partial | ✅ 12 checks |
| `MAVLink_Messages` | 1/1 | ✅ | ✅ 0 checks |
| `Position_Types` | 1/1 | ✅ | ✅ 0 checks |
| `Zone_Types` | 1/1 | ✅ | ✅ 0 checks |

### Non-Verifiable Islets (Justified)

| Function | Cause | Mitigation |
|---------|-------|------------|
| `Haversine_Distance` | `Sin/Cos/Arctan` not in SPARK | Unit tests DO-178C §6.4.2 |
| `To_Float` | Float-fixedpoint conversion | Static limits + review |
