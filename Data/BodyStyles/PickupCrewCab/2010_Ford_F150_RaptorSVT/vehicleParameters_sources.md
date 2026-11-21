# Sources for vehicleParameters_2010_Ford_F150_RaptorSVT.mat

Vehicle: US 2010 F-150 SVT Raptor SuperCab 4x4 (the only 2010 body), 133 in wheelbase, 5.5 ft box, 5.4 L V8.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2010, Ford, F-150, RaptorSVT | P | US 2010 F-150 SVT Raptor SuperCab 4x4 (the only 2010 body), 133 in wheelbase, 5.5 ft box, 5.4 L V8. |
| MassCurb, Mass | 2679.8 kg | P | 5,908 lb (kbb.com) |
| MassCurbFrontAxle | 1500.7 kg | E | Not published; typical front share for an empty pickup (56%) |
| MassCurbRearAxle | 1179.1 kg | C | Curb mass - front-axle mass |
| MassGross | 3152.0 kg | P | 3152 kg gross vehicle weight (auto123.com) |
| DistancesWheelbase | 3.378 m | P | 133 in (hagerty.com; 3378 mm, auto123.com) |
| DistancesLength | 5.611 m | P | 220.9 in (edmunds.com; kbb.com) |
| DistancesWidth | 2.192 m | P | 86.3 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.462 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.991 m | P | 78.4 in (edmunds.com) |
| DistancesGroundClearance | 0.284 m | P | 11.2 in (kbb.com) |
| DistancesFrontTrack | 1.869 m | P | 73.6 in (Ford 2011 SVT Raptor technical specifications, same body) |
| DistancesRearTrack | 1.869 m | P | 73.6 in (same) |
| DistancesFrontOverhang | 0.994 m | E | Not published. 44% of the total overhang (length - wheelbase = 2.233 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 1.239 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.892 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.80 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | LT315/70R17 | P | BFGoodrich All-Terrain T/A KO LT315/70R17 (the Raptor tire) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 6.86 m | C | Half of the turning diameter: Not looked up for the SuperCab; 47.0 ft for the longer SuperCrew (truecar.com) |
| Ixx, IxxCurb / IxxGross | 1132 / 1309 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 5250 / 5415 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 5487 / 5757 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 5.400 L | P | 5.4 L V8 (edmunds.com) |
| EngineCylinders | 8 | P | V8 |
| EnginePeakHorsepower | 310.0 hp | P | 310 hp (hagerty.com) |
| EngineSpeedAtPeakHorsepower | 5000 rpm | E | Not looked up: the usual peak speed of this engine |
| EngineTorqueAtPeakHorsepower | 325.6 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 8.0 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
