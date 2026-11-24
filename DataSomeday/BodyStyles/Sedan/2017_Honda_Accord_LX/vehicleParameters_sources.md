# Sources for vehicleParameters_2017_Honda_Accord_LX.mat

Vehicle: US 2017 Accord LX sedan (ninth generation, facelift), 2.4 L I-4, CVT. LX was chosen by Claude as the most common trim (the folder was 2017_Honda_Accord, with no trim).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2017, Honda, Accord, LX | P | US 2017 Accord LX sedan (ninth generation, facelift), 2.4 L I-4, CVT. LX was chosen by Claude as the most common trim (the folder was 2017_Honda_Accord, with no trim). |
| MassCurb, Mass | 1469.2 kg | P | 3,239 lb, LX CVT (kbb.com; edmunds.com; cars.com) |
| MassCurbFrontAxle | 896.2 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 573.0 kg | C | Curb mass - front-axle mass |
| MassGross | 1919.2 kg | E | Not published by these sources; curb mass + 450 kg (five occupants and luggage) |
| DistancesWheelbase | 2.776 m | P | 109.3 in (cars.com, 109 in rounded; same as 2013) |
| DistancesLength | 4.889 m | P | 192.5 in (edmunds.com, 2017 sedan) |
| DistancesWidth | 1.849 m | E | 72.8 in: the 2013 value (same body; cars.com lists 73 in, rounded) |
| DistancesWidthWithMirrors | 2.119 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.466 m | P | 57.7 in (edmunds.com) |
| DistancesGroundClearance | 0.147 m | P | cars.com lists 6 in (rounded); 5.8 in used |
| DistancesFrontTrack | 1.585 m | E | cars.com lists 63 in (rounded); the 2013 LX value, 62.4 in, used |
| DistancesRearTrack | 1.582 m | E | cars.com lists 63 in (rounded); the 2013 LX value, 62.3 in, used |
| DistancesFrontOverhang | 1.162 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.113 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.951 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.693 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P205/65HR16 | P | LX (cars.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.81 m | C | Half of the turning diameter: 38.1 ft turning circle, LX (kbb.com; edmunds.com) |
| Ixx, IxxCurb / IxxGross | 394 / 506 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2116 / 2424 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2265 / 2640 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.400 L | P | 2.4 L I-4 (edmunds.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 185.0 hp | P | 185 hp @ 6400 rpm (edmunds.com) |
| EngineSpeedAtPeakHorsepower | 6400 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 151.8 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 7.6 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
