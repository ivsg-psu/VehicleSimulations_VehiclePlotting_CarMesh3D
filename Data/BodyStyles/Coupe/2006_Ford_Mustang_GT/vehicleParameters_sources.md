# Sources for vehicleParameters_2006_Ford_Mustang_GT.mat

Vehicle: US 2006 Mustang GT Deluxe coupe (fifth generation, S197), 4.6 L V8, 5-speed manual, rear-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2006, Ford, Mustang, GT | P | US 2006 Mustang GT Deluxe coupe (fifth generation, S197), 4.6 L V8, 5-speed manual, rear-wheel drive. |
| MassCurb, Mass | 1582.1 kg | P | 3,488 lb, GT Deluxe manual (edmunds.com) |
| MassCurbFrontAxle | 838.5 kg | E | Not published by these sources; typical front share for a front-engine V8 coupe (53%) |
| MassCurbRearAxle | 743.6 kg | C | Curb mass - front-axle mass |
| MassGross | 2030.3 kg | P | 4,476 lb GVWR (truecar.com, 2009 GT coupe, same body) |
| DistancesWheelbase | 2.720 m | P | 107.1 in (edmunds.com; truedelta.com) |
| DistancesLength | 4.775 m | P | 188.0 in, GT (edmunds.com; autobytel.com) |
| DistancesWidth | 1.877 m | P | 73.9 in without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.147 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.382 m | P | 54.4 in, GT coupe (edmunds.com) |
| DistancesGroundClearance | 0.145 m | P | 5.71 in (autobytel.com, 2006 Mustang) |
| DistancesFrontTrack | 1.582 m | P | 62.3 in (edmunds.com, GT; autobytel.com) |
| DistancesRearTrack | 1.587 m | P | 62.5 in (edmunds.com, GT Premium; autobytel.com) |
| DistancesFrontOverhang | 0.929 m | E | Not published. 45% of the total overhang (length - wheelbase = 2.055 m): the share in the downloaded 3D model (its axle positions); check against a side photo |
| DistancesRearOverhang | 1.126 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.442 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.50 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | P235/55ZR17 | P | GT standard 17 in wheels (Ford 2006 GT; cars.com lists 17 in for GT) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.75 m | C | Half of the turning diameter: 37.7 ft turning diameter (truecar.com, 2009 GT coupe, same body) |
| Ixx, IxxCurb / IxxGross | 414 / 522 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2161 / 2432 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2350 / 2690 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 4.600 L | P | 4.6 L V8 (truecar.com) |
| EngineCylinders | 8 | P | V8 |
| EnginePeakHorsepower | 300.0 hp | P | 300 hp @ 5750 rpm (truecar.com, GT; kbb.com) |
| EngineSpeedAtPeakHorsepower | 5750 rpm | P | (same) |
| EngineTorqueAtPeakHorsepower | 274.0 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 5.1 s | P | 5.1 s, GT Deluxe (kbb.com) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
