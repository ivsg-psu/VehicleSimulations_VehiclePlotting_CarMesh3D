# Sources for vehicleParameters_2021_Subaru_Outback_LimitedXT.mat

Vehicle: US 2021 Subaru Outback Limited XT (sixth generation), 2.4 L turbo H-4, CVT.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2021, Subaru, Outback, LimitedXT | P | US 2021 Subaru Outback Limited XT (sixth generation), 2.4 L turbo H-4, CVT. |
| MassCurb, Mass | 1780.8 kg | P | 3,926 lb (edmunds.com; subaru.com) |
| MassCurbFrontAxle | 1050.7 kg | E | Not published; typical front share for an all-wheel-drive car of this kind (59%) |
| MassCurbRearAxle | 730.1 kg | C | Curb mass - front-axle mass |
| MassGross | 2279.8 kg | P | 5,026 lb gross weight (autoblog.com, 2021 Onyx Edition XT) |
| DistancesWheelbase | 2.746 m | P | 108.1 in (edmunds.com) |
| DistancesLength | 4.859 m | P | 191.3 in (edmunds.com; motormatchup.com) |
| DistancesWidth | 1.854 m | P | 73.0 in without mirrors (edmunds.com; jdpower.com) |
| DistancesWidthWithMirrors | 2.124 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.679 m | P | 66.1 in (edmunds.com; others list 66.4 in with roof rails) |
| DistancesGroundClearance | 0.221 m | P | 8.7 in (edmunds.com) |
| DistancesFrontTrack | 1.570 m | P | 61.8 in (jdpower.com; subaru.com) |
| DistancesRearTrack | 1.595 m | P | 62.8 in (jdpower.com; subaru.com) |
| DistancesFrontOverhang | 1.162 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.113 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.951 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.620 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.64 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | 225/60R18 | P | (auto123.com, XT trims) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.50 m | C | Half of the turning diameter: 36.1 ft curb to curb (jdpower.com) |
| Ixx, IxxCurb / IxxGross | 537 / 675 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2601 / 2920 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2718 / 3104 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.400 L | P | 2.4 L turbo H-4 (subaru.com) |
| EngineCylinders | 4 | P | H-4 (flat four) |
| EnginePeakHorsepower | 260.0 hp | P | 260 hp @ 5600 rpm (subaru.com) |
| EngineSpeedAtPeakHorsepower | 5600 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 243.8 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 6.2 s | P | 6.2 s (motormatchup.com, Touring XT) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
