# Sources for vehicleParameters_2012_Honda_Civic_Si.mat

Vehicle: US 2012 Civic Si coupe (ninth generation), 2.4 L I-4, 6-speed manual.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2012, Honda, Civic, Si | P | US 2012 Civic Si coupe (ninth generation), 2.4 L I-4, 6-speed manual. |
| MassCurb, Mass | 1305.0 kg | P | 2,877 lb, Si coupe manual (hondanews.com) |
| MassCurbFrontAxle | 796.0 kg | C | Curb mass x 0.610 front share: 61/39 front/rear (hondanews.com) |
| MassCurbRearAxle | 508.9 kg | C | Curb mass - front-axle mass |
| MassGross | 1785.3 kg | P | 3,936 lb GVWR (truecar.com, 2013 Si coupe, same body) |
| DistancesWheelbase | 2.621 m | P | 103.2 in (hondanews.com) |
| DistancesLength | 4.458 m | P | 175.5 in, Si coupe (hondanews.com 2012 Civic Si specifications) |
| DistancesWidth | 1.753 m | P | 69.0 in (hondanews.com) |
| DistancesWidthWithMirrors | 2.023 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.397 m | P | 55.0 in (hondanews.com) |
| DistancesGroundClearance | 0.140 m | E | Not published by these sources; typical for this compact coupe |
| DistancesFrontTrack | 1.499 m | P | 59.0 in (hondanews.com) |
| DistancesRearTrack | 1.521 m | P | 59.9 in (hondanews.com) |
| DistancesFrontOverhang | 0.887 m | E | Not published. 48% of the total overhang (length - wheelbase = 1.836 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 0.949 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.599 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.50 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P215/45ZR17 | P | 215/45 ZR17 91W (hondanews.com; cars.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.39 m | C | Half of the turning diameter: 35.4 ft turning diameter (truecar.com, 2013 Si coupe) |
| Ixx, IxxCurb / IxxGross | 316 / 425 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 1574 / 1888 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 1689 / 2062 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.354 L | P | 2.4 L I-4 (hondanews.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 201.0 hp | P | 201 hp @ 7000 rpm (truecar.com, 2013 Si coupe, same engine) |
| EngineSpeedAtPeakHorsepower | 7000 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 150.8 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 6.7 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
