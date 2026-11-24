# Sources for vehicleParameters_2023_Honda_Accord_SE.mat

Vehicle: US eleventh-generation Accord with the 1.5 L turbo I-4 and 17 in wheels. The SE trim was added in 2025; the 2023 equivalent is the EX (same engine, wheels, and body), so published EX and SE values are used.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2023, Honda, Accord, SE | P | US eleventh-generation Accord with the 1.5 L turbo I-4 and 17 in wheels. The SE trim was added in 2025; the 2023 equivalent is the EX (same engine, wheels, and body), so published EX and SE values are used. |
| MassCurb, Mass | 1487.8 kg | P | 3,280 lb (cars.com, 2025 SE; iseecars.com, 2023 EX) |
| MassCurbFrontAxle | 907.5 kg | E | Not published; typical front share for a front-drive car of this kind (61%) |
| MassCurbRearAxle | 580.2 kg | C | Curb mass - front-axle mass |
| MassGross | 1937.8 kg | E | Not published by these sources; curb mass + 450 kg (five occupants and luggage) |
| DistancesWheelbase | 2.830 m | P | 111.4 in (hondanews.com) |
| DistancesLength | 4.971 m | P | 195.7 in (hondanews.com, 2024 specifications; auto123.com, 2023 EX) |
| DistancesWidth | 1.862 m | P | 73.3 in without mirrors (hondanews.com) |
| DistancesWidthWithMirrors | 2.132 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.450 m | P | 57.1 in (hondanews.com) |
| DistancesGroundClearance | 0.135 m | P | 5.3 in unladen (hondanews.com) |
| DistancesFrontTrack | 1.600 m | P | 63.0 in (hondanews.com, 1.5 L trims) |
| DistancesRearTrack | 1.621 m | P | 63.8 in (hondanews.com) |
| DistancesFrontOverhang | 1.178 m | E | Not published. 55% of the total overhang (length - wheelbase = 2.141 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.963 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.726 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P225/50VR17 | P | (cars.com; auto123.com, 2023 EX) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.85 m | C | Half of the turning diameter: 38.4 ft curb to curb (hondanews.com; hondainfocenter.com) |
| Ixx, IxxCurb / IxxGross | 399 / 511 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2205 / 2518 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2365 / 2748 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 1.500 L | P | 1.5 L turbo I-4 |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 192.0 hp | P | 192 hp @ 6000 rpm (hondainfocenter.com) |
| EngineSpeedAtPeakHorsepower | 6000 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 168.1 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 7.4 s | E | Not looked up; typical published values |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
