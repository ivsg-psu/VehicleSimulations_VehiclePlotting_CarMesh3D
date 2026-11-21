# Sources for vehicleParameters_2014_Volvo_V60_RDesign.mat

Vehicle: US Volvo V60 T6 AWD R-Design (first generation, 2014 facelift), 3.0 L turbo I-6, 6-speed automatic. Most dimensions are the 2015 US model year's, the first US year for the V60 (the same car).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2014, Volvo, V60, RDesign | P | US Volvo V60 T6 AWD R-Design (first generation, 2014 facelift), 3.0 L turbo I-6, 6-speed automatic. Most dimensions are the 2015 US model year's, the first US year for the V60 (the same car). |
| MassCurb, Mass | 1719.1 kg | P | 3,790 lb (autoblog.com; motormatchup.com) |
| MassCurbFrontAxle | 1014.3 kg | E | Not published; typical front share for an all-wheel-drive car of this kind (59%) |
| MassCurbRearAxle | 704.8 kg | C | Curb mass - front-axle mass |
| MassGross | 2310.0 kg | P | 2310 kg (topgear.com) |
| DistancesWheelbase | 2.776 m | P | 109.3 in (autoblog.com) |
| DistancesLength | 4.635 m | P | 182.5 in (autoblog.com; motormatchup.com) |
| DistancesWidth | 1.864 m | P | 73.4 in without mirrors (autoblog.com) |
| DistancesWidthWithMirrors | 2.097 m | P | 2097 mm with mirrors (topgear.com, UK T6 R-Design) |
| DistancesHeight | 1.483 m | P | 58.4 in (autoblog.com) |
| DistancesGroundClearance | 0.137 m | P | 5.4 in (autoblog.com) |
| DistancesFrontTrack | 1.578 m | P | 1578 mm with 17 in wheels (Volvo press data, mb.cision.com) |
| DistancesRearTrack | 1.575 m | P | 1575 mm with 17 in wheels (Volvo press data) |
| DistancesFrontOverhang | 1.023 m | E | Not published. 55% of the total overhang (length - wheelbase = 1.859 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.836 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.638 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.56 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | 235/40R18 | E | R-Design 18 in wheels (autoblog.com, 2014 S60 R-Design review); the size is typical for them |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.95 m | P | 11.9 m curb to curb with larger wheels (Volvo press data, V60 plug-in hybrid); 5.95 m radius |
| Ixx, IxxCurb / IxxGross | 470 / 621 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2251 / 2652 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2422 / 2902 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 3.000 L | P | 3.0 L turbo I-6 (cars.com) |
| EngineCylinders | 6 | P | I-6 |
| EnginePeakHorsepower | 325.0 hp | P | 325 hp @ 5600 rpm (cars.com, 2015 V60 T6 R-Design) |
| EngineSpeedAtPeakHorsepower | 5600 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 304.8 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 5.4 s | P | 5.4 s (autoblog.com) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
