# Sources for vehicleParameters_2005_Toyota_HiAce_H200DX.mat

Vehicle: Japan-market 2005 HiAce Van DX (fifth generation, H200), long body, standard width and roof, CBF-TRH200V: 2.0 L 1TR-FE I-4, 4-speed automatic, rear-wheel drive, cab-over.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2005, Toyota, HiAce, H200DX | P | Japan-market 2005 HiAce Van DX (fifth generation, H200), long body, standard width and roof, CBF-TRH200V: 2.0 L 1TR-FE I-4, 4-speed automatic, rear-wheel drive, cab-over. |
| MassCurb, Mass | 1650.0 kg | P | 1650 kg (221616.com) |
| MassCurbFrontAxle | 858.0 kg | E | Not published; typical front share of an empty cab-over van (52%) |
| MassCurbRearAxle | 792.0 kg | C | Curb mass - front-axle mass |
| MassGross | 3065.0 kg | E | Not looked up; curb mass + 1250 kg payload + 3 occupants |
| DistancesWheelbase | 2.570 m | P | 2570 mm (221616.com) |
| DistancesLength | 4.695 m | P | 4695 mm (221616.com catalog, TRH200V DX 2004-08 to 2005-11; toyota.jp) |
| DistancesWidth | 1.695 m | P | 1695 mm (221616.com; toyota.jp) |
| DistancesWidthWithMirrors | 1.965 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.980 m | P | 1980 mm, standard roof (221616.com) |
| DistancesGroundClearance | 0.195 m | P | 195 mm (221616.com) |
| DistancesFrontTrack | 1.506 m | E | Not published by these sources; from the downloaded 3D model (its wheel positions, scaled by the published wheelbase); check |
| DistancesRearTrack | 1.506 m | E | Not published by these sources; from the downloaded 3D model (its wheel positions, scaled by the published wheelbase); check |
| DistancesFrontOverhang | 1.065 m | E | Not published. 50% of the total overhang (length - wheelbase = 2.125 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 1.060 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.336 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.80 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | 195/80R15 | P | 195/80R15 LT (221616.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.00 m | P | 5.0 m minimum turning radius (221616.com) |
| Ixx, IxxCurb / IxxGross | 540 / 986 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2368 / 3857 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2320 / 3844 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 1.998 L | P | 2.0 L 1TR-FE (221616.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 131.2 hp | P | 133 PS (98 kW) @ 5600 rpm (221616.com) = 131.2 hp |
| EngineSpeedAtPeakHorsepower | 5600 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 123.0 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 16.0 s | E | Not published; typical for this van |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
