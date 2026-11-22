# Sources for vehicleParameters_2009_Honda_Fit_Sport.mat

Vehicle: US 2009 Honda Fit Sport, 5-door hatchback (second generation, GE8), 1.5 L I-4, 5-speed manual.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

## The trim was inferred

The model's author (ActsOfDoge, "2009 Honda Fit" on Sketchfab) does not name a trim; the download arrived as `2009_Honda_Fit_XXX`. The model has every exterior item that Honda lists for the 2009 US Fit Sport and not for the base Fit: fog lights, a body-colored underbody kit (front chin spoiler and side sills), a rear roofline spoiler, and 16 in alloy wheels (the base Fit has 15 in wheels with full covers). Sources: Honda's 2009 Fit Sport overview and 2009 Fit specifications and features (hondanews.com). The model's rim-to-tire size ratio (0.71) also fits the Sport's 185/55R16 better than the base's 175/65R15. Hence **Trim = Sport, TrimStatus = E**, with the reasoning in `TrimSource`. Pictures: `fit_trim_views.png` and `fit_trim_closeups.png` in Claude's project folder.

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2009, Honda, Fit, Sport | P (trim E) | Model title "2009 Honda Fit"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | New fields (vehicleParameters change request 16) |
| MassCurb, Mass | 1143 kg | C | 2,520 lb, Fit Sport manual (hondanews.com, 2010 Fit specifications; same body, unchanged from 2009) |
| MassCurbFrontAxle | 697 kg | E | Curb mass x 0.61, a typical front share for a front-engine, front-drive hatchback |
| MassCurbRearAxle | 446 kg | C | Curb mass - front-axle mass |
| MassGross | 1543 kg | E | Curb mass + 400 kg (GVWR not found) |
| Ixx, Iyy, Izz (curb and gross) | from the 2012 Civic Si | E | The Civic Si's values scaled by mass and by the squares of this car's dimensions |
| DistancesWheelbase | 2.499 m | P | 98.4 in (hondanews.com 2009 Fit specifications; jdpower.com) |
| DistancesLength | 4.105 m | P | 161.6 in (hondanews.com) |
| DistancesWidth | 1.694 m | P | 66.7 in, without mirrors (jdpower.com; edmunds.com) |
| DistancesWidthWithMirrors | 2.024 m | E | Not published. The model's full width over its body width (2.041 / 1.708 = 1.195) times the published width. The model's mirrors may be oversized: the usual rule here (width + 0.27 m) gives 1.964 m |
| DistancesHeight | 1.524 m | P | 60.0 in (hondanews.com; jdpower.com) |
| DistancesGroundClearance | 0.150 m | P | 150 mm unladen: Honda Australia, Jazz GE specifications (2008), the same body; 5.9 in for the 2009 to 2013 US Fit (getjerry.com). The model's own clearance is 0.186 m, so the fit lowers the body |
| DistancesFrontTrack | 1.476 m | P | 58.1 in, Fit Sport (jdpower.com 2009 Fit Sport; auto-data.net 1476 mm) |
| DistancesRearTrack | 1.458 m | P | 57.4 in, Fit Sport (jdpower.com; auto-data.net 1458 mm) |
| DistancesFrontOverhang | 0.925 m | E | Not published. From the downloaded model's front axle and bumper, scaled to the published length |
| DistancesRearOverhang | 0.680 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.525 m | C | Wheelbase x 0.61 (the front share above) |
| DistancesCGAboveGround | 0.55 m | E | Not published; typical for a tall hatchback of this height |
| TireSidewallMarkings | 185/55R16 83H | P | Fit Sport (hondanews.com 2009 Fit specifications; cargurus.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.24 m | C | Half of the 34.4 ft curb-to-curb turning diameter (hondanews.com; kbb.com) |
| EngineDisplacement, EngineCylinders | 1.497 L, 4 | P | 1.5 L / 1497 cc in-line 4 (hondanews.com) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 117 hp at 6,600 rpm | P | (hondanews.com 2010 Fit specifications; tc-v.com, same L15A engine) |
| EngineTorqueAtPeakHorsepower | 93.1 ft-lb | C | 117 hp x 5252 / 6600 rpm |
| AccelerationZeroToSixtyTime | 9.5 s | E | Not checked against a road test; typical for this car |
| EngineType | sparkIgnition | P | Gasoline engine |
