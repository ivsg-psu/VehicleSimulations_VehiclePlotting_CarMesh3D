# Sources for vehicleParameters_2004_Toyota_RAV4_L.mat

Vehicle: 2004 RAV4 five-door (second generation, XA20; "RAV4 L" is the Japanese name of the five-door), with the values of the US 2004 RAV4 FWD automatic, 2.4 L I-4.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2004, Toyota, RAV4, L | P | 2004 RAV4 five-door (second generation, XA20; "RAV4 L" is the Japanese name of the five-door), with the values of the US 2004 RAV4 FWD automatic, 2.4 L I-4. |
| MassCurb, Mass | 1344.9 kg | P | 2,965 lb (edmunds.com; velocityjournal.com) |
| MassCurbFrontAxle | 820.4 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 524.5 kg | C | Curb mass - front-axle mass |
| MassGross | 1810.0 kg | P | 1810 kg gross vehicle weight (auto123.com, Canadian 2004 RAV4) |
| DistancesWheelbase | 2.489 m | P | 98.0 in (edmunds.com; kbb.com) |
| DistancesLength | 4.232 m | P | 166.6 in (edmunds.com; kbb.com) |
| DistancesWidth | 1.735 m | P | 68.3 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.005 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.669 m | P | 65.7 in, FWD (edmunds.com) |
| DistancesGroundClearance | 0.160 m | P | 6.3 in, FWD (edmunds.com; kbb.com) |
| DistancesFrontTrack | 1.506 m | P | 59.3 in (velocityjournal.com) |
| DistancesRearTrack | 1.501 m | P | 59.1 in (edmunds.com; velocityjournal.com) |
| DistancesFrontOverhang | 0.768 m | E | Not published. 44% of the total overhang (length - wheelbase = 1.742 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 0.974 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.518 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.65 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P215/70R16 | P | 215/70 R16 (carexpert.com.au; carsales.com.au; 16 x 6.5 in wheels, cars.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.39 m | C | Half of the turning diameter: 35.4 ft turning diameter (kbb.com) |
| Ixx, IxxCurb / IxxGross | 375 / 497 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 1538 / 1815 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 1587 / 1905 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.362 L | P | 2.4 L I-4 (2AZ-FE) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 161.0 hp | E | 161 hp @ 5700 rpm: the widely published value for the 2004 RAV4 (not looked up here) |
| EngineSpeedAtPeakHorsepower | 5700 rpm | E | (same) |
| EngineTorqueAtPeakHorsepower | 148.3 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 9.5 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
