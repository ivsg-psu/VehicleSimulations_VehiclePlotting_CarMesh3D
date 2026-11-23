# Sources for vehicleParameters_2021_Chevrolet_Suburban_LT.mat

Vehicle: US 2021 Chevrolet Suburban LT, full-size SUV (twelfth generation, T1), 5.3 L V8, 10-speed automatic.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row.

## The trim was inferred

The model's author (ActsOfDoge, "2021 Chevrolet Suburban" on Sketchfab) does not name a trim; the download arrived as `2021_Chevrolet_Suburban_XXX`. The model has 20 in machined wheels (its wheel material is named `20in`), a chrome grille, and silver running boards. For 2021, the LS has 18 in wheels, the RST black trim and 22 in wheels, the Z71 a dark grille and skid plates, and the Premier and High Country 22 in wheels (cars.com: 275/65R20 on the Premier as listed; 275/60R20 on the Z71). The LT, with 20 in wheels and a chrome grille, fits best. Hence **Trim = LT, TrimStatus = E**. Picture: `suburban_raw.png` in Claude's project folder (scratch\suburban).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2021, Chevrolet, Suburban, LT | P (trim E) | Model title "2021 Chevrolet Suburban"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 2577.8 kg | C | 5,683 lb, LT (truecar.com; edmunds.com lists 5,824 lb for the LT 4x4) |
| MassCurbFrontAxle | 1362.2 kg | C | The Z71's published axle split (3,003 lb front of 5,683 lb; cars.com), applied to the curb mass |
| MassCurbRearAxle | 1215.6 kg | C | Curb mass - front-axle mass |
| MassGross | 3492.7 kg | C | 7,700 lb GVWR (truecar.com; edmunds.com) |
| Ixx, Iyy, Izz (curb and gross) | 986, 5209, 5394 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this SUV's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 3.406 m | P | 134.1 in (kbb.com; conceptcarz.com/NHTSA 3406 mm) |
| DistancesLength | 5.733 m | P | 225.7 in (edmunds.com; kbb.com) |
| DistancesWidth | 2.060 m | P | 81.1 in, without mirrors (jdpower.com; conceptcarz.com) |
| DistancesWidthWithMirrors | 2.287 m | E | Not found. The model's full width over its body width (1.933 / 1.742 = 1.110) times the published width |
| DistancesHeight | 1.923 m | P | 75.7 in (edmunds.com; conceptcarz.com) |
| DistancesGroundClearance | 0.203 m | P | 8.0 in (autoblog.com; iseecars.com) |
| DistancesFrontTrack | 1.740 m | P | 68.5 in (conceptcarz.com/NHTSA; iseecars.com) |
| DistancesRearTrack | 1.735 m | P | 68.3 in (conceptcarz.com/NHTSA; iseecars.com) |
| DistancesFrontOverhang | 0.950 m | E | Not published. From the downloaded model's front axle and bumper, scaled to the published length |
| DistancesRearOverhang | 1.377 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.800 m | C | Wheelbase x the front-axle share above |
| DistancesCGAboveGround | 0.85 m | E | Not published; typical for a full-size SUV |
| TireSidewallMarkings | 275/60R20 | E | The 20 in size (cars.com, 2021 Suburban Z71); the LT's 20 in option is taken to be the same |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 6.45 m | C | Half of the 42.3 ft turning diameter (truecar.com, LT 4WD) |
| EngineDisplacement, EngineCylinders | 5.3 L, 8 | P | 5.3 L V8, the LT's standard engine (kbb.com: every 2021 Suburban has a V8) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 355 hp at 5,600 rpm | E | Chevrolet's usual figures for this engine; not checked against a 2021 source |
| EngineTorqueAtPeakHorsepower | 332.9 ft-lb | C | 355 hp x 5252 / 5600 rpm |
| AccelerationZeroToSixtyTime | 7.5 s | E | Not checked against a road test; typical for this SUV |
| EngineType | sparkIgnition | P | Gasoline (flex-fuel) engine |
