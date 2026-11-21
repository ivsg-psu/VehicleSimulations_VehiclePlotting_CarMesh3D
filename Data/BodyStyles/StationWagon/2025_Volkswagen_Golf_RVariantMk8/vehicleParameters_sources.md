# Sources for vehicleParameters_2025_Volkswagen_Golf_RVariantMk8.mat

Vehicle: European 2025 Golf R Variant (Mk8.5 facelift, from 07/2024), 2.0 L turbo I-4, 4MOTION, DSG. Note: the Variant is a station wagon (estate).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2025, Volkswagen, Golf, RVariantMk8 | P | European 2025 Golf R Variant (Mk8.5 facelift, from 07/2024), 2.0 L turbo I-4, 4MOTION, DSG. Note: the Variant is a station wagon (estate). |
| MassCurb, Mass | 1546.0 kg | P | 1621 kg EU kerb weight with a 75 kg driver (adac.de), less the driver |
| MassCurbFrontAxle | 890.5 kg | C | Curb mass x 0.576 front share: 57.6/42.4 front/rear, test car (auto-motor-und-sport.de, earlier Mk8 R Variant) |
| MassCurbRearAxle | 655.5 kg | C | Curb mass - front-axle mass |
| MassGross | 2110.0 kg | P | 2110 kg (adac.de) |
| DistancesWheelbase | 2.678 m | P | 2678 mm (adac.de) |
| DistancesLength | 4.651 m | P | 4651 mm (adac.de) |
| DistancesWidth | 1.789 m | P | 1789 mm without mirrors (adac.de) |
| DistancesWidthWithMirrors | 2.073 m | P | 2073 mm with mirrors (adac.de) |
| DistancesHeight | 1.462 m | P | 1462 mm (adac.de) |
| DistancesGroundClearance | 0.128 m | E | 128 mm: the Golf R hatchback (angurten.de); not published for the Variant |
| DistancesFrontTrack | 1.539 m | P | 1539 mm (carwow.de; meinauto.de) |
| DistancesRearTrack | 1.516 m | P | 1516 mm (carwow.de; meinauto.de) |
| DistancesFrontOverhang | 1.085 m | E | Not published. 55% of the total overhang (length - wheelbase = 1.973 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.888 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.543 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | 225/40R18 | P | (adac.de; its text mentions 19 in wheels as an option) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 6.10 m | C | Half of the turning diameter: 12.2 m (adac.de) |
| Ixx, IxxCurb / IxxGross | 398 / 533 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2031 / 2431 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2166 / 2637 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 1.984 L | P | 1984 cc (adac.de) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 328.4 hp | P | 245 kW (333 PS) @ 5600 rpm (adac.de) = 328.4 hp |
| EngineSpeedAtPeakHorsepower | 5600 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 308.0 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 4.8 s | P | 4.8 s 0-100 km/h (adac.de); 0-60 mph is slightly less |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
