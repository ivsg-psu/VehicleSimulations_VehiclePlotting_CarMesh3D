# Sources for vehicleParameters_2002_Toyota_Camry_XV30LE.mat

Vehicle: US 2002 Camry LE, 2.4 L I-4, 4-speed automatic (generation XV30).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2002, Toyota, Camry, LE | P | US 2002 Camry LE, 2.4 L I-4, 4-speed automatic (generation XV30). |
| MassCurb, Mass | 1425.2 kg | P | 3,142 lb, LE automatic (kbb.com; cars.com) |
| MassCurbFrontAxle | 869.4 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 555.8 kg | C | Curb mass - front-axle mass |
| MassGross | 1875.2 kg | E | Not published by these sources; curb mass + 450 kg (five occupants and luggage) |
| DistancesWheelbase | 2.720 m | P | 107.1 in (kbb.com; edmunds.com) |
| DistancesLength | 4.806 m | P | 189.2 in (edmunds.com; motormatchup.com) |
| DistancesWidth | 1.796 m | P | 70.7 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.066 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.491 m | P | 58.7 in, LE (motormatchup.com; 1490 mm, carexpert.com.au) |
| DistancesGroundClearance | 0.147 m | P | 5.8 in (edmunds.com, 2002 XLE) |
| DistancesFrontTrack | 1.544 m | P | 60.8 in (edmunds.com, 2002 XLE, same body) |
| DistancesRearTrack | 1.534 m | P | 60.4 in (edmunds.com, 2002 XLE) |
| DistancesFrontOverhang | 1.147 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.085 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.938 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.659 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P205/65R15 | P | LE (cars.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.30 m | C | Half of the turning diameter: 34.8 ft turning circle, LE (kbb.com) |
| Ixx, IxxCurb / IxxGross | 374 / 484 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 1994 / 2301 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2117 / 2484 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.400 L | P | 2.4 L I-4 (cars.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 157.0 hp | P | 157 hp @ 5600 rpm (cars.com; edmunds.com) |
| EngineSpeedAtPeakHorsepower | 5600 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 147.2 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 8.8 s | P | 8.8 s (motormatchup.com, LE) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
