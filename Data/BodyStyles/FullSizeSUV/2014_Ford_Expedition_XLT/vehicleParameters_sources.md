# Sources for vehicleParameters_2014_Ford_Expedition_XLT.mat

Vehicle: US 2014 Ford Expedition XLT, regular length (not EL), 4x2, 5.4 L V8, 17 in wheels.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row.

**The model:** "Ford Expedition 2014" by Doz3 on Sketchfab, **CC Attribution** (the credit line is in LICENSE.txt and must go with any picture of this vehicle). Its title names no trim; the folder name (XLT) was chosen at download, and the model's 17 in off-road wheels fit the XLT's standard 265/70R17 (TrimStatus 'E').

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2014, Ford, Expedition, XLT | E (trim) | As above |
| MassCurb, Mass | 2517 kg | P | 5,549 lb, 2WD XLT (cars.com) |
| MassCurbFrontAxle | 1260 kg | P | 2,777 lb front (cars.com) |
| MassCurbRearAxle | 1257 kg | C | Curb mass - front-axle mass (2,772 lb rear, cars.com) |
| MassGross | 3284 kg | C | Curb mass + the 1,690 lb maximum payload (edmunds.com) |
| Ixx, Iyy, Izz (curb and gross) | from the 2015 F-150 Lariat | E | Its values scaled by mass and by the squares of this vehicle's dimensions |
| DistancesWheelbase | 3.023 m | P | 119.0 in (Ford brochure via dealer.com; edmunds.com) |
| DistancesLength | 5.245 m | P | 206.5 in (Ford brochure; edmunds.com) |
| DistancesWidth | 2.002 m | P | 78.8 in, without mirrors (Ford brochure) |
| DistancesWidthWithMirrors | 2.332 m | P | 91.8 in, including mirrors (Ford brochure) |
| DistancesHeight | 1.961 m | P | 77.2 in, including options (Ford brochure; edmunds.com) |
| DistancesGroundClearance | 0.221 m | P | 8.7 in, minimum running clearance (Ford brochure; edmunds.com) |
| DistancesFrontTrack | 1.702 m | P | 67.0 in (iseecars.com) |
| DistancesRearTrack | 1.707 m | P | 67.2 in (edmunds.com; iseecars.com) |
| DistancesFrontOverhang | 0.996 m | P | 39.2 in (Ford brochure) |
| DistancesRearOverhang | 1.227 m | C | Length - wheelbase - front overhang (the brochure gives 48.3 in = 1.227 m) |
| DistancesCGFromRearAxle | 1.513 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.80 m | E | Typical for a full-size SUV |
| TireSidewallMarkings | P265/70R17 | P | XLT standard (truedelta.com; edmunds.com) |
| TireFrontCorneringCoefficient, TireRearCorneringCoefficient | from the 2015 F-150 | E | Typical values |
| MinimumTurnRadius | 6.4 m | E | Not found; typical for this size |
| EngineDisplacement, EngineCylinders | 5.4 L, 8 | P | 5.4 L 3-valve V8 (Ford brochure; carmax.com) |
| EnginePeakHorsepower | 310 hp | P | (carmax.com) |
| EngineSpeedAtPeakHorsepower | 5,100 rpm | E | Not found in these sources |
| EngineTorqueAtPeakHorsepower | 319.2 ft-lb | C | 310 hp x 5252 / 5100 rpm (peak torque 365 lb-ft, carmax.com) |
| AccelerationZeroToSixtyTime | 8.5 s | E | Not checked against a road test |
| EngineType | sparkIgnition | P | Gasoline (flex-fuel) engine |
