# Sources for vehicleParameters_2015_Ford_F150_Lariat.mat

Vehicle: US 2015 F-150 Lariat SuperCrew 4x2 (thirteenth generation), 145 in wheelbase, 5.5 ft box. The 3D model has 20 in off-road wheels; its cab and box are checked in the first look.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2015, Ford, F-150, Lariat | P | US 2015 F-150 Lariat SuperCrew 4x2 (thirteenth generation), 145 in wheelbase, 5.5 ft box. The 3D model has 20 in off-road wheels; its cab and box are checked in the first look. |
| MassCurb, Mass | 2069.7 kg | P | 4,563 lb, Lariat SuperCrew 4x2 5.5 ft box (autoblog.com) |
| MassCurbFrontAxle | 1179.8 kg | E | Not published; typical front share for an empty pickup (57%) |
| MassCurbRearAxle | 890.0 kg | C | Curb mass - front-axle mass |
| MassGross | 2835.0 kg | P | 6,250 lb (autoblog.com) |
| DistancesWheelbase | 3.683 m | P | 145.0 in (iseecars.com; autoblog.com) |
| DistancesLength | 5.890 m | P | 231.9 in, SuperCrew 5.5 ft box (iseecars.com; autoblog.com) |
| DistancesWidth | 2.029 m | P | 79.9 in without mirrors (autoblog.com) |
| DistancesWidthWithMirrors | 2.459 m | P | 96.8 in with mirrors (iseecars.com) |
| DistancesHeight | 1.913 m | P | 75.3 in, 4x2 (iseecars.com) |
| DistancesGroundClearance | 0.221 m | P | 8.7 in, Lariat 4x2 (autoblog.com) |
| DistancesFrontTrack | 1.717 m | P | 67.6 in (iseecars.com) |
| DistancesRearTrack | 1.717 m | P | 67.6 in (iseecars.com) |
| DistancesFrontOverhang | 0.960 m | E | Not published. 44% of the total overhang (length - wheelbase = 2.207 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 1.247 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 2.099 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.75 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P275/55R20 | E | The 3D model has 20 in wheels; the 275/55R20 size of the 2015 F-150's 20 in option |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 7.16 m | C | Half of the turning diameter: 47.0 ft (truecar.com, 2013 SuperCrew 5.5 ft box; check for 2015) |
| Ixx, IxxCurb / IxxGross | 775 / 1044 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 4387 / 5270 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 4533 / 5538 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.700 L | E | Not looked up: the 2.7 L EcoBoost V6, usually listed as the Lariat's standard engine |
| EngineCylinders | 6 | E | V6 |
| EnginePeakHorsepower | 325.0 hp | E | 325 hp @ 5750 rpm (not looked up) |
| EngineSpeedAtPeakHorsepower | 5750 rpm | E | (same) |
| EngineTorqueAtPeakHorsepower | 296.9 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 7.3 s | E | 7.3 s (autotk.com, 2015 F-150, engine not stated) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
