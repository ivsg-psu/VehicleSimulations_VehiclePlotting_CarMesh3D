# Sources for vehicleParameters_2010_Toyota_Camry_XV40.mat

Vehicle: US 2010 Camry LE (the most common trim), 2.5 L I-4, 6-speed automatic. The ID keeps the generation code (XV40) as its trim part; the values are the LE's.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2010, Toyota, Camry, XV40 | P | US 2010 Camry LE (the most common trim), 2.5 L I-4, 6-speed automatic. The ID keeps the generation code (XV40) as its trim part; the values are the LE's. |
| MassCurb, Mass | 1500.0 kg | P | 3,307 lb, LE automatic (kbb.com; iseecars.com) |
| MassCurbFrontAxle | 915.0 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 585.0 kg | C | Curb mass - front-axle mass |
| MassGross | 1950.0 kg | E | Not published by these sources; curb mass + 450 kg (five occupants and luggage) |
| DistancesWheelbase | 2.776 m | P | 109.3 in (kbb.com; edmunds.com) |
| DistancesLength | 4.806 m | P | 189.2 in (edmunds.com, 2010 LE) |
| DistancesWidth | 1.821 m | P | 71.7 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.091 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.471 m | P | 57.9 in (cars.com lists 58 in, rounded; 57.9 in is the published LE value; check) |
| DistancesGroundClearance | 0.142 m | P | cars.com lists 5 to 6 in (rounded) by trim; 5.6 in used |
| DistancesFrontTrack | 1.575 m | P | 62.0 in (edmunds.com, 2010 LE) |
| DistancesRearTrack | 1.565 m | P | 61.6 in (edmunds.com) |
| DistancesFrontOverhang | 1.116 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.029 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.913 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.693 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P215/60R16 | P | LE (cars.com; edmunds.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.50 m | C | Half of the turning diameter: 36.1 ft turning circle (kbb.com; edmunds.com) |
| Ixx, IxxCurb / IxxGross | 396 / 506 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2094 / 2387 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2236 / 2592 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.500 L | P | 2.5 L I-4 (edmunds.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 169.0 hp | P | 169 hp @ 6000 rpm (edmunds.com) |
| EngineSpeedAtPeakHorsepower | 6000 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 147.9 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 8.9 s | E | Not looked up; typical published values are 8.5 to 9.5 s |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
