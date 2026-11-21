# Sources for vehicleParameters_2017_Toyota_RAV4_XLE.mat

Vehicle: US 2017 RAV4 XLE FWD (fourth generation, XA40), 2.5 L I-4, 6-speed automatic.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2017, Toyota, RAV4, XLE | P | US 2017 RAV4 XLE FWD (fourth generation, XA40), 2.5 L I-4, 6-speed automatic. |
| MassCurb, Mass | 1580.8 kg | P | 3,485 lb, XLE FWD (autoblog.com) |
| MassCurbFrontAxle | 964.3 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 616.5 kg | C | Curb mass - front-axle mass |
| MassGross | 2052.5 kg | P | 4,525 lb, XLE FWD (autoblog.com) |
| DistancesWheelbase | 2.659 m | P | 104.7 in (edmunds.com) |
| DistancesLength | 4.661 m | P | 183.5 in (edmunds.com; autoblog.com) |
| DistancesWidth | 1.844 m | P | 72.6 in (edmunds.com) |
| DistancesWidthWithMirrors | 2.114 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.704 m | P | 67.1 in (edmunds.com) |
| DistancesGroundClearance | 0.155 m | P | 6.1 in (edmunds.com; kbb.com) |
| DistancesFrontTrack | 1.570 m | P | 61.8 in (carbuzz.com; iseecars.com) |
| DistancesRearTrack | 1.570 m | P | 61.8 in (iseecars.com) |
| DistancesFrontOverhang | 0.953 m | E | Not published. 48% of the total overhang (length - wheelbase = 2.002 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 1.049 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.622 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.65 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P225/65R17 | P | P225/65HR17 (cars.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.30 m | E | Not looked up; 34.8 ft turning circle of the Australian 2017 RAV4 (carsguide.com.au) / 2 |
| Ixx, IxxCurb / IxxGross | 480 / 613 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2152 / 2450 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2241 / 2596 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.494 L | P | 2.5 L I-4 |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 176.0 hp | P | 176 hp (kbb.com) |
| EngineSpeedAtPeakHorsepower | 6000 rpm | E | Not looked up: the usual peak speed of this engine |
| EngineTorqueAtPeakHorsepower | 154.1 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 8.8 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
