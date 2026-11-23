# Sources for vehicleParameters_2006_Nissan_Frontier_SEKingCab.mat

Vehicle: US 2006 Nissan Frontier SE King Cab, midsize pickup (second generation, D40), 4.0 L V6, 2WD, 6 ft bed.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row.

## The trim was inferred

The model's author (ActsOfDoge, "2006 Nissan Frontier" on Sketchfab; the file inside is named "2008 Nissan Frontier") does not name a trim; the download arrived as `2006_Nissan_Frontier_XXX`. The model is a King Cab (small rear-access doors) with alloy wheels; its tires scale to 0.75 m across. For 2006, the XE had 15 in steel wheels (P235/75R15, 0.73 m), the SE 16 in alloys (P265/70R16, 0.78 m), and the LE 17 in alloys (P265/65R17) (cars.com 2006 Frontier specifications). The SE fits best. Its wheel material is named `18in`, a name ActsOfDoge reuses on many models. Hence **Trim = SE King Cab, TrimStatus = E**. Picture: `frontier_raw.png` in Claude's project folder (scratch\frontier).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2006, Nissan, Frontier, SE King Cab | P (trim E) | Model title "2006 Nissan Frontier"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 1814.4 kg | E | 4,000 lb: between the King Cab XE (3,675 lb) and LE (4,176 lb) (kbb.com); the SE King Cab V6 2WD's own figure was not found |
| MassCurbFrontAxle | 1034.2 kg | E | Curb mass x 0.57, typical for an unloaded pickup |
| MassCurbRearAxle | 780.2 kg | C | Curb mass - front-axle mass |
| MassGross | 2540.1 kg | E | 5,600 lb, near the V6 King Cabs' published gross weights (edmunds.com: 5,619 to 5,836 lb) |
| Ixx, Iyy, Izz (curb and gross) | 573, 3046, 3138 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this truck's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 3.198 m | P | 125.9 in (cars.com 2006 Frontier overview; edmunds.com) |
| DistancesLength | 5.220 m | P | 205.5 in (cars.com; edmunds.com) |
| DistancesWidth | 1.849 m | P | 72.8 in (edmunds.com; kbb.com lists it as "with mirrors", taken here as the body width) |
| DistancesWidthWithMirrors | 2.128 m | E | The model's full width over its body width (1.151) times the published width |
| DistancesHeight | 1.770 m | P | 69.7 in, King Cab (cars.com 2006 Frontier overview) |
| DistancesGroundClearance | 0.249 m | P | 9.8 in (edmunds.com 2006 Frontier) |
| DistancesFrontTrack | 1.570 m | P | 61.8 in (edmunds.com) |
| DistancesRearTrack | 1.570 m | P | 61.8 in (edmunds.com) |
| DistancesFrontOverhang | 0.788 m | E | Not published. From the downloaded model's front axle and bumper, scaled to the published length (the model's wheelbase scales to 3.185 m) |
| DistancesRearOverhang | 1.234 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.823 m | C | Wheelbase x 0.57 (the front share above) |
| DistancesCGAboveGround | 0.75 m | E | Not published; typical for a midsize pickup |
| TireSidewallMarkings | P265/70R16 | P | SE (cars.com 2006 Frontier SE) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 6.61 m | C | Half of the 43.4 ft turning diameter (kbb.com, 2006 Frontier King Cab) |
| EngineDisplacement, EngineCylinders | 4.0 L, 6 | P | 4.0 L V6 (kbb.com: 265 hp for the V6 King Cabs) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 265 hp at 5,600 rpm | P (rpm E) | 265 hp (kbb.com); the engine speed was not checked against a Nissan source |
| EngineTorqueAtPeakHorsepower | 248.5 ft-lb | C | 265 hp x 5252 / 5600 rpm |
| AccelerationZeroToSixtyTime | 7.9 s | E | Not checked against a road test; typical for this truck |
| EngineType | sparkIgnition | P | Gasoline engine |
