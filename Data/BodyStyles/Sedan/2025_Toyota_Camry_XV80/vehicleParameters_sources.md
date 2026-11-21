# Sources for vehicleParameters_2025_Toyota_Camry_XV80.mat

Vehicle: US 2025 Camry LE FWD (the base trim; every 2025 Camry is a hybrid), 2.5 L I-4 hybrid, CVT. The ID keeps the generation code (XV80) as its trim part; the values are the LE FWD's.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2025, Toyota, Camry, XV80 | P | US 2025 Camry LE FWD (the base trim; every 2025 Camry is a hybrid), 2.5 L I-4 hybrid, CVT. The ID keeps the generation code (XV80) as its trim part; the values are the LE FWD's. |
| MassCurb, Mass | 1564.9 kg | P | 3,450 lb, LE FWD (edmunds.com; cars.com) |
| MassCurbFrontAxle | 954.6 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 610.3 kg | C | Curb mass - front-axle mass |
| MassGross | 2014.9 kg | E | Not published by these sources; curb mass + 450 kg (five occupants and luggage) |
| DistancesWheelbase | 2.824 m | P | 111.2 in (auto123.com; carexpert.com.au) |
| DistancesLength | 4.915 m | P | 193.5 in (auto123.com) |
| DistancesWidth | 1.839 m | P | 72.4 in without mirrors (auto123.com) |
| DistancesWidthWithMirrors | 2.120 m | P | 2120 mm with mirrors (carexpert.com.au, Australian Ascent, same body) |
| DistancesHeight | 1.445 m | P | 56.9 in (auto123.com; carexpert.com.au) |
| DistancesGroundClearance | 0.137 m | P | 5.4 in (iseecars.com; auto123.com) |
| DistancesFrontTrack | 1.600 m | P | 63.0 in, LE (iseecars.com) |
| DistancesRearTrack | 1.615 m | P | 63.6 in, LE (iseecars.com) |
| DistancesFrontOverhang | 1.150 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.090 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.940 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.723 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P205/65VR16 | P | LE (cars.com; truedelta.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.70 m | C | Half of the turning diameter: 11.4 m kerb to kerb (carexpert.com.au) |
| Ixx, IxxCurb / IxxGross | 412 / 522 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2270 / 2563 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2432 / 2793 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 2.500 L | P | 2.5 L I-4 hybrid (truedelta.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 184.0 hp | P | 184 hp @ 6000 rpm for the engine alone (truedelta.com); the combined hybrid output is higher |
| EngineSpeedAtPeakHorsepower | 6000 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 161.1 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 7.6 s | E | Not looked up; typical published values for the FWD LE |
| EngineType, EngineHybridEngineType | hybrid, sparkIgnition | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
