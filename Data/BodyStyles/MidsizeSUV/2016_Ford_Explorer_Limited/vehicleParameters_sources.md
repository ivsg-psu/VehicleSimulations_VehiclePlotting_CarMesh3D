# Sources for vehicleParameters_2016_Ford_Explorer_Limited.mat

Vehicle: US 2016 Ford Explorer Limited, three-row midsize SUV (fifth generation, U502, 2016 refresh), 3.5 L V6, 6-speed automatic, front-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row.

## The trim was inferred

The model's author (ActsOfDoge, "2016 Ford Explorer" on Sketchfab) does not name a trim; the download arrived as `2016_Ford_Explorer_XXX`. The model has 20 in machined alloy wheels (its wheel material is named `20in`) and chrome front accents. For 2016, the base and XLT had 18 in wheels, the Sport dark 20 in wheels with a black grille, and the Limited and Platinum 20 in wheels (autopadre.com: P255/50HR20 on the Limited). The Limited, the more common of the two, was taken; the dimensions are the same. Hence **Trim = Limited, TrimStatus = E**. Picture: `explorer_raw.png` in Claude's project folder (scratch\explorer).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2016, Ford, Explorer, Limited | P (trim E) | Model title "2016 Ford Explorer"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 2015.3 kg | C | 4,443 lb, Limited FWD (edmunds.com; autoblog.com) |
| MassCurbFrontAxle | 1108.4 kg | E | Curb mass x 0.55, typical for a front-engine three-row SUV |
| MassCurbRearAxle | 906.9 kg | C | Curb mass - front-axle mass |
| MassGross | 2794.1 kg | C | 6,160 lb gross weight (autoblog.com) |
| Ixx, Iyy, Izz (curb and gross) | 697, 3178, 3340 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this SUV's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 2.865 m | P | 112.8 in (Ford 2016 Explorer brochure; kbb.com) |
| DistancesLength | 5.037 m | P | 198.3 in (Ford brochure) |
| DistancesWidth | 2.004 m | P | 78.9 in, excluding mirrors (Ford brochure) |
| DistancesWidthWithMirrors | 2.291 m | P | 90.2 in, including mirrors (Ford brochure; edmunds.com) |
| DistancesHeight | 1.778 m | P | 70.0 in (Ford brochure; edmunds.com) |
| DistancesGroundClearance | 0.198 m | P | 7.8 in, Limited FWD (edmunds.com; 8.3 in for 4WD) |
| DistancesFrontTrack | 1.702 m | P | 67.0 in (cars.com; iseecars.com) |
| DistancesRearTrack | 1.702 m | P | 67.0 in (cars.com; iseecars.com) |
| DistancesFrontOverhang | 0.947 m | E | Not published. From the downloaded model's front axle and bumper, scaled to the published length |
| DistancesRearOverhang | 1.225 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.576 m | C | Wheelbase x 0.55 (the front share above) |
| DistancesCGAboveGround | 0.72 m | E | Not published; typical for a midsize SUV |
| TireSidewallMarkings | P255/50R20 | P | Limited (autopadre.com; velocityjournal.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.93 m | C | Half of the 38.9 ft curb-to-curb turning diameter (autopadre.com) |
| EngineDisplacement, EngineCylinders | 3.497 L, 6 | P | 3.5 L V6 (velocityjournal.com 3497 cc; truedelta.com) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 290 hp at 6,500 rpm | P | (truedelta.com) |
| EngineTorqueAtPeakHorsepower | 234.3 ft-lb | C | 290 hp x 5252 / 6500 rpm (peak torque 255 lb-ft at 4,000 rpm) |
| AccelerationZeroToSixtyTime | 7.5 s | E | Not checked against a road test; typical for this SUV |
| EngineType | sparkIgnition | P | Gasoline (flex-fuel) engine |
