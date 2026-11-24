# Sources for vehicleParameters_2007_Volkswagen_Golf_Mk5GTI.mat

Vehicle: US 2007 Volkswagen GTI 4-door (Golf Mk5), 2.0 L turbo I-4.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2007, Volkswagen, Golf, Mk5GTI | P | US 2007 Volkswagen GTI 4-door (Golf Mk5), 2.0 L turbo I-4. |
| MassCurb, Mass | 1428.8 kg | P | 3,150 lb, 4-door (edmunds.com) |
| MassCurbFrontAxle | 871.6 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 557.2 kg | C | Curb mass - front-axle mass |
| MassGross | 1889.7 kg | P | 4,166 lb gross weight (edmunds.com) |
| DistancesWheelbase | 2.578 m | P | 101.5 in (edmunds.com) |
| DistancesLength | 4.211 m | P | 165.8 in (edmunds.com) |
| DistancesWidth | 1.760 m | P | 69.3 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.030 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.483 m | P | 58.4 in (edmunds.com) |
| DistancesGroundClearance | 0.142 m | P | 5.6 in (edmunds.com) |
| DistancesFrontTrack | 1.534 m | P | 60.4 in (edmunds.com) |
| DistancesRearTrack | 1.516 m | P | 59.7 in (edmunds.com) |
| DistancesFrontOverhang | 0.898 m | E | Not published. 55% of the total overhang (length - wheelbase = 1.633 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.735 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.573 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | 225/45R17 | P | (edmunds.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.46 m | C | Half of the turning diameter: 35.8 ft turning circle (edmunds.com; kbb.com) |
| Ixx, IxxCurb / IxxGross | 365 / 474 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 1574 / 1826 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 1680 / 1981 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.000 L | P | 2.0 L turbo I-4 |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 200.0 hp | P | 200 hp (kbb.com); 5100 rpm is the commonly published speed |
| EngineSpeedAtPeakHorsepower | 5100 rpm | E | Not confirmed by these sources |
| EngineTorqueAtPeakHorsepower | 206.0 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 7.0 s | P | 7 s (kbb.com) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
