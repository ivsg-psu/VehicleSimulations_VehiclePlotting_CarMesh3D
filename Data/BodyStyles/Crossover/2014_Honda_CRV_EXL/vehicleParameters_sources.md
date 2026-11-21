# Sources for vehicleParameters_2014_Honda_CRV_EXL.mat

Vehicle: US 2014 CR-V EX-L 2WD (fourth generation), 2.4 L I-4, 5-speed automatic. The 3D model is a 2015 CR-V (the facelift, same body and wheelbase).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2014, Honda, CR-V, EX-L | P | US 2014 CR-V EX-L 2WD (fourth generation), 2.4 L I-4, 5-speed automatic. The 3D model is a 2015 CR-V (the facelift, same body and wheelbase). |
| MassCurb, Mass | 1553.1 kg | P | 3,424 lb, EX-L 2WD (edmunds.com) |
| MassCurbFrontAxle | 947.4 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 605.7 kg | C | Curb mass - front-axle mass |
| MassGross | 2024.8 kg | P | 4,464 lb (autoblog.com, 2014 CR-V LX AWD; check) |
| DistancesWheelbase | 2.619 m | P | 103.1 in (edmunds.com) |
| DistancesLength | 4.529 m | P | 178.3 in (edmunds.com, EX-L; autopadre.com) |
| DistancesWidth | 1.819 m | P | 71.6 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.089 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.643 m | P | 64.7 in, 2WD (edmunds.com) |
| DistancesGroundClearance | 0.160 m | P | 6.3 in, 2WD (edmunds.com) |
| DistancesFrontTrack | 1.567 m | P | 61.7 in (edmunds.com, EX-L 2WD) |
| DistancesRearTrack | 1.567 m | P | 61.7 in (edmunds.com) |
| DistancesFrontOverhang | 0.926 m | E | Not published. 48% of the total overhang (length - wheelbase = 1.910 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 0.984 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.597 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.65 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P225/65R17 | P | P225/65TR17 (autopadre.com, EX-L) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.50 m | C | Half of the turning diameter: 11.0 m kerb to kerb (carexpert.com.au, 2014 CR-V) |
| Ixx, IxxCurb / IxxGross | 449 / 576 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 1992 / 2278 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2087 / 2427 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.354 L | P | 2.4 L I-4 |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 185.0 hp | P | 185 hp (cars.com, 2014 CR-V) |
| EngineSpeedAtPeakHorsepower | 7000 rpm | E | Not looked up: the usual peak speed of this engine |
| EngineTorqueAtPeakHorsepower | 138.8 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 9.0 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
