# Sources for vehicleParameters_2002_Subaru_Outback_Legacy.mat

Vehicle: US 2002 Subaru Outback wagon (the Legacy-based Outback, second generation), 2.5 L H-4, 4-speed automatic.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2002, Subaru, Outback, Legacy | P | US 2002 Subaru Outback wagon (the Legacy-based Outback, second generation), 2.5 L H-4, 4-speed automatic. |
| MassCurb, Mass | 1583.0 kg | P | 3,490 lb (edmunds.com; cars.com lists 3,415 lb) |
| MassCurbFrontAxle | 934.0 kg | E | Not published; typical front share for an all-wheel-drive car of this kind (59%) |
| MassCurbRearAxle | 649.0 kg | C | Curb mass - front-axle mass |
| MassGross | 2033.0 kg | E | Not published by these sources; curb mass + 450 kg (five occupants and luggage) |
| DistancesWheelbase | 2.649 m | P | 104.3 in (edmunds.com) |
| DistancesLength | 4.760 m | P | 187.4 in (edmunds.com) |
| DistancesWidth | 1.745 m | P | 68.7 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.015 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.608 m | P | 63.3 in (edmunds.com) |
| DistancesGroundClearance | 0.185 m | P | 7.3 in (edmunds.com) |
| DistancesFrontTrack | 1.471 m | P | 57.9 in (edmunds.com) |
| DistancesRearTrack | 1.466 m | P | 57.7 in (edmunds.com) |
| DistancesFrontOverhang | 1.161 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.111 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.950 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.563 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.60 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | 225/60HR16 | P | (cars.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.59 m | C | Half of the turning diameter: 36.7 ft turning circle (edmunds.com) |
| Ixx, IxxCurb / IxxGross | 429 / 542 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2208 / 2487 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2296 / 2630 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.500 L | P | 2.5 L H-4 (edmunds.com) |
| EngineCylinders | 4 | P | H-4 (flat four) |
| EnginePeakHorsepower | 165.0 hp | E | 165 hp: the 2002 Legacy's (kbb.com), same engine; 5600 rpm not confirmed |
| EngineSpeedAtPeakHorsepower | 5600 rpm | E | Not confirmed |
| EngineTorqueAtPeakHorsepower | 154.7 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 10.0 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
