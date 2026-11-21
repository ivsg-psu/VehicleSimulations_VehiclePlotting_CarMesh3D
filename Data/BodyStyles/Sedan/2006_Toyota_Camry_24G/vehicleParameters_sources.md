# Sources for vehicleParameters_2006_Toyota_Camry_24G.mat

Vehicle: Japan-market 2006 Camry 2.4G (DBA-ACV40, generation XV40), launched January 2006; 2AZ-FE 2.4 L I-4, 5-speed automatic.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2006, Toyota, Camry, 24G | P | Japan-market 2006 Camry 2.4G (DBA-ACV40, generation XV40), launched January 2006; 2AZ-FE 2.4 L I-4, 5-speed automatic. |
| MassCurb, Mass | 1500.0 kg | P | 1500 kg (toyota.jp) |
| MassCurbFrontAxle | 915.0 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 585.0 kg | C | Curb mass - front-axle mass |
| MassGross | 1775.0 kg | P | 1775 kg vehicle gross weight (kurumaerabi.com) |
| DistancesWheelbase | 2.775 m | P | 2775 mm (toyota.jp) |
| DistancesLength | 4.815 m | P | 4815 mm (toyota.jp; kurumaerabi.com; autoc-one.jp) |
| DistancesWidth | 1.820 m | P | 1820 mm without mirrors (toyota.jp) |
| DistancesWidthWithMirrors | 2.090 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.470 m | P | 1470 mm (toyota.jp) |
| DistancesGroundClearance | 0.150 m | P | 150 mm (autoc-one.jp) |
| DistancesFrontTrack | 1.575 m | P | 1575 mm (toyota.jp) |
| DistancesRearTrack | 1.565 m | P | 1565 mm (toyota.jp) |
| DistancesFrontOverhang | 1.122 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.040 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.918 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.693 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P215/60R16 | E | Not found for the Japan 2.4G; the size of the same-generation US Camry LE (cars.com, 2010 LE) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.50 m | P | 5.5 m minimum turning radius (kurumaerabi.com; carsensor.net) |
| Ixx, IxxCurb / IxxGross | 395 / 460 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2101 / 2180 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2243 / 2367 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.362 L | P | 2362 cc (toyota.jp) |
| EngineCylinders | 4 | P | I-4 (2AZ-FE) |
| EnginePeakHorsepower | 164.7 hp | P | 167 PS (123 kW) @ 6000 rpm (toyota.jp) = 164.7 hp |
| EngineSpeedAtPeakHorsepower | 6000 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 144.2 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 9.5 s | E | Not published; typical for this engine and weight |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
