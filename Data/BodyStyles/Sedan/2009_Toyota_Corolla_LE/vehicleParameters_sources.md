# Sources for vehicleParameters_2009_Toyota_Corolla_LE.mat

Vehicle: US 2009 Toyota Corolla LE sedan (tenth generation, E140), 1.8 L I-4, with the optional 16 in alloy wheels.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

## The model year and trim were inferred

The model's author (ActsOfDoge, "2008 Toyota Corolla" on Sketchfab) does not name a trim; the download arrived as `2008_Toyota_Corolla_XXX`.

- **Year:** the model has the tenth-generation (E140) body. In the US that body was sold from the 2009 model year (on sale February 2008); the 2008 US Corolla is the ninth generation. The parameters are the US 2009 Corolla's, so the ID is `2009_Toyota_Corolla_LE` (the README rule: the year of the vehicle whose parameters are used).
- **Trim:** the model has a chrome-barred grille, alloy wheels, and no fog lamps, rocker moldings, or spoilers. The S and XRS have fog lamps, a body kit (front spoiler, rocker moldings, rear spoilers), and a blackout grille; the XRS has a rear deck spoiler and 17 in alloys (Toyota press releases; jdpower.com; kbb.com). The Standard (CE) has 15 in steel wheels; the LE and XLE offer 16 in alloys as an option. LE is taken as the most common of the two: **Trim = LE, TrimStatus = E**. Pictures: `corolla_trim_views.png` and `corolla_trim_closeups.png` in Claude's project folder.

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2009, Toyota, Corolla, LE | P (year and trim E) | As above |
| TrimStatus, TrimSource | E; the reasoning above | E | New fields (vehicleParameters change request 16) |
| MassCurb, Mass | 1245 kg | P | 2,745 lb, LE (edmunds.com) |
| MassCurbFrontAxle | 759 kg | E | Curb mass x 0.61, typical for a front-engine, front-drive sedan |
| MassCurbRearAxle | 486 kg | C | Curb mass - front-axle mass |
| MassGross | 1740 kg | P | 3,836 lb gross weight (autoblog.com, 2010 Corolla S; the same body and engine) |
| Ixx, Iyy, Izz (curb and gross) | from the 2009 Fit Sport | E | Its values scaled by mass and by the squares of this car's dimensions |
| DistancesWheelbase | 2.601 m | P | 102.4 in (Toyota Canada 2010 Corolla specifications: 2600 mm; kbb.com) |
| DistancesLength | 4.539 m | P | 178.7 in (Toyota Canada: 4540 mm; kbb.com) |
| DistancesWidth | 1.760 m | P | 69.3 in, without mirrors (edmunds.com; Toyota Canada: 1760 mm) |
| DistancesWidthWithMirrors | 1.985 m | E | Not published. The model's full width over its body width (1.970 / 1.747) times the published width |
| DistancesHeight | 1.466 m | P | 57.7 in (Toyota Canada: 1465 mm, unloaded) |
| DistancesGroundClearance | 0.147 m | P | 5.8 in (kbb.com; edmunds.com; Toyota Canada: 147 mm for all but the XRS) |
| DistancesFrontTrack | 1.532 m | P | 60.3 in (jdpower.com 2009 Corolla S, 16 in wheels; iseecars.com) |
| DistancesRearTrack | 1.534 m | P | 60.4 in (jdpower.com; Toyota Canada: 1534 mm) |
| DistancesFrontOverhang | 0.896 m | E | Not published. 46% of the total overhang (length - wheelbase = 1.938 m): the share in the downloaded model (its axle positions) |
| DistancesRearOverhang | 1.042 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.587 m | C | Wheelbase x 0.61 (the front share above) |
| DistancesCGAboveGround | 0.52 m | E | Not published; typical for a sedan of this height |
| TireSidewallMarkings | P205/55R16 | P | The LE's optional 16 in alloy wheels (jdpower.com 2009 Corolla preview; Toyota pressroom) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.43 m | C | Half of the 35.6 ft turning diameter (kbb.com; edmunds.com) |
| EngineDisplacement, EngineCylinders | 1.798 L, 4 | P | 1.8 L four-cylinder (Toyota Canada) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 132 hp at 6,000 rpm | P | (Toyota Canada, 2009 Corolla preliminary specifications) |
| EngineTorqueAtPeakHorsepower | 115.5 ft-lb | C | 132 hp x 5252 / 6000 rpm |
| AccelerationZeroToSixtyTime | 9.5 s | E | Not checked against a road test; typical for this car |
| EngineType | sparkIgnition | P | Gasoline engine |
