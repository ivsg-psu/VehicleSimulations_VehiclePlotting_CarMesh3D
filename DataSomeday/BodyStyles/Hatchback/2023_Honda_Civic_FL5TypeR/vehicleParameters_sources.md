# Sources for vehicleParameters_2023_Honda_Civic_FL5TypeR.mat

Vehicle: US 2023 Honda Civic Type R (FL5), 2.0 L turbo I-4, 6-speed manual.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-20 from the web pages named in each row (the sites' own published specifications).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2023, Honda, Civic, FL5TypeR | P | US 2023 Honda Civic Type R (FL5), 2.0 L turbo I-4, 6-speed manual. |
| MassCurb, Mass | 1446.1 kg | P | 3,188 lb (hondanews.com) |
| MassCurbFrontAxle | 896.6 kg | C | Curb mass x 0.620 front share: 62/38 front/rear (hondanews.com) |
| MassCurbRearAxle | 549.5 kg | C | Curb mass - front-axle mass |
| MassGross | 1800.0 kg | P | 1800 kg gross vehicle mass (carexpert.com.au, Australian version) |
| DistancesWheelbase | 2.736 m | P | 107.7 in (hondanews.com) |
| DistancesLength | 4.595 m | P | 180.9 in (hondanews.com) |
| DistancesWidth | 1.890 m | P | 74.4 in without mirrors (hondanews.com) |
| DistancesWidthWithMirrors | 2.160 m | E | Not published by these sources; the width without mirrors + 0.27 m, the average difference for the vehicles here with both values published (0.23 to 0.30 m) |
| DistancesHeight | 1.407 m | P | 55.4 in (hondanews.com) |
| DistancesGroundClearance | 0.122 m | P | 4.8 in (hondanews.com) |
| DistancesFrontTrack | 1.626 m | P | 64.0 in (hondanews.com) |
| DistancesRearTrack | 1.613 m | P | 63.5 in (hondanews.com) |
| DistancesFrontOverhang | 1.023 m | E | Not published. 55% of the total overhang (length - wheelbase = 1.859 m), typical for a front-engine car; check against the model or a side photo |
| DistancesRearOverhang | 0.836 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.696 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.50 m | E | Not published; typical for a car of this height and body style |
| TireSidewallMarkings | 265/30R19 | P | 265/30 R19 Michelin Pilot Sport 4S (hondanews.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 6.08 m | C | Half of the turning diameter: 39.9 ft curb to curb (hondainfocenter.com; kbb.com) |
| Ixx, IxxCurb / IxxGross | 387 / 473 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 1845 / 2015 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-height diagonal) |
| Izz, IzzCurb / IzzGross | 2014 / 2236 kg-m^2 | E | Prius values scaled by mass and by the size of the car (radius of gyration scaled by the length-width diagonal) |
| EngineDisplacement | 1.996 L | P | 1996 cc (hondanews.com) |
| EngineCylinders | 4 | P | I-4 |
| EnginePeakHorsepower | 315.0 hp | E | 315 hp (kbb.com); 6500 rpm is the commonly published speed |
| EngineSpeedAtPeakHorsepower | 6500 rpm | E | Not confirmed by these sources |
| EngineTorqueAtPeakHorsepower | 254.5 ft-lb | C | Peak horsepower x 5252 / its engine speed |
| AccelerationZeroToSixtyTime | 5.2 s | P | 5.2 s (parkers.co.uk) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | From the engine above |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2014 Transit Connect file.
