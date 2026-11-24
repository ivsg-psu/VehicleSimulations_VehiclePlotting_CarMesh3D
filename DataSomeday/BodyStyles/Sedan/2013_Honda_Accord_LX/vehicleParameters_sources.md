# Sources for vehicleParameters_2013_Honda_Accord_LX.mat

Vehicle: US 2013 Accord LX sedan (ninth generation), 2.4 L I-4. LX was chosen by Claude as the most common trim (the folder was 2013_Honda_Accord, with no trim).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2013, Honda, Accord, LX | P | US 2013 Accord LX sedan (ninth generation), 2.4 L I-4. LX was chosen by Claude as the most common trim (the folder was 2013_Honda_Accord, with no trim). |
| MassCurb, Mass | 1447.9 kg | P | 3,192 lb, LX (carspecs.us; cars.com) |
| MassCurbFrontAxle | 883.2 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 564.7 kg | C | Curb mass - front-axle mass |
| MassGross | 1897.9 kg | E | Not published by these sources; curb mass + 450 kg (five occupants and luggage) |
| DistancesWheelbase | 2.776 m | P | 109.3 in (carspecs.us; edmunds.com) |
| DistancesLength | 4.862 m | P | 191.4 in (carspecs.us, 2013 LX sedan) |
| DistancesWidth | 1.849 m | P | 72.8 in without mirrors (carspecs.us; edmunds.com) |
| DistancesWidthWithMirrors | 2.119 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.466 m | P | 57.7 in (carspecs.us; edmunds.com) |
| DistancesGroundClearance | 0.147 m | E | Not published by these sources; typical for this sedan |
| DistancesFrontTrack | 1.585 m | P | 62.4 in (carspecs.us, LX) |
| DistancesRearTrack | 1.582 m | P | 62.3 in (carspecs.us, LX) |
| DistancesFrontOverhang | 1.147 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.085 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.938 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.693 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P205/65R16 | E | The LX size for this generation (cars.com lists P205/65HR16 for the 2017 LX) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.81 m | C | Half of the turning diameter: 38.1 ft turning circle (carspecs.us) |
| Ixx, IxxCurb / IxxGross | 388 / 500 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2063 / 2372 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2210 / 2584 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.400 L | P | 2.4 L I-4 (edmunds.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 185.0 hp | E | 185 hp @ 6400 rpm: the 2017 LX value (edmunds.com), same engine |
| EngineSpeedAtPeakHorsepower | 6400 rpm | E | (same) |
| EngineTorqueAtPeakHorsepower | 151.8 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 7.6 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
