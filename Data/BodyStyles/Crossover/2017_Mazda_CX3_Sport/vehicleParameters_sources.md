# Sources for vehicleParameters_2017_Mazda_CX3_Sport.mat

Vehicle: US 2017 Mazda CX-3 Sport, subcompact crossover (DK), 2.0 L I-4, 6-speed automatic, front-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-22 (a draft for Sean to check) from the web pages named in each row.

## The trim was inferred

The model's author (ActsOfDoge, "2017 Mazda CX-3" on Sketchfab) does not name a trim; the download arrived as `2017_Mazda_CX3_XXX`. The model's wheels are alloys, its wheel material is named `16in`, and its tires are 0.66 m across (a 215/60R16 is 0.664 m). For 2017, 16 in alloy wheels with 215/60R16 tires were the Sport's; the Touring and Grand Touring had 18 in wheels with 215/50R18 tires (Mazda's 2017 CX-3 specification deck, news.mazdausa.com). Hence **Trim = Sport, TrimStatus = E**. The paint is Soul Red. Picture: `cx3_raw.png` in Claude's project folder (scratch\cx3).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2017, Mazda, CX-3, Sport | P (trim E) | Model title "2017 Mazda CX-3"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 1274.1 kg | C | 2,809 lb, Sport FWD (autoblog.com; edmunds.com) |
| MassCurbFrontAxle | 764.5 kg | E | Curb mass x 0.60, typical for a front-drive crossover |
| MassCurbRearAxle | 509.6 kg | C | Curb mass - front-axle mass |
| MassGross | 1741.8 kg | C | 3,840 lb gross weight, Sport FWD (autoblog.com) |
| Ixx, Iyy, Izz (curb and gross) | 338, 1454, 1538 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this crossover's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 2.570 m | P | 101.2 in (edmunds.com; carexpert.com.au 2570 mm) |
| DistancesLength | 4.275 m | P | 168.3 in (edmunds.com; kbb.com) |
| DistancesWidth | 1.768 m | P | 69.6 in, without mirrors (edmunds.com) |
| DistancesWidthWithMirrors | 2.024 m | E | The model's full width over its body width (1.145) times the published width (kbb.com's "68.1 in with mirrors" is below the body width, so it was not used) |
| DistancesHeight | 1.542 m | P | 60.7 in, Sport (edmunds.com; the Touring and Grand Touring are 60.9 in) |
| DistancesGroundClearance | 0.155 m | P | 6.1 in, Sport (edmunds.com; kbb.com) |
| DistancesFrontTrack | 1.524 m | P | 60.0 in (iseecars.com) |
| DistancesRearTrack | 1.521 m | P | 59.9 in (iseecars.com) |
| DistancesFrontOverhang | 0.904 m | E | Not published. From the downloaded model's front axle and bumper (the model is at full size) |
| DistancesRearOverhang | 0.800 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.542 m | C | Wheelbase x 0.60 (the front share above) |
| DistancesCGAboveGround | 0.58 m | E | Not published; typical for a small crossover |
| TireSidewallMarkings | 215/60R16 | P | Sport (Mazda 2017 CX-3 specification deck) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.30 m | C | Half of the 34.8 ft turning circle (edmunds.com; kbb.com) |
| EngineDisplacement, EngineCylinders | 2.0 L, 4 | P | 2.0 L in-line 4 (kbb.com: every 2017 CX-3 has a 4-cylinder) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 146 hp at 6,000 rpm | E | Mazda's usual figures for this engine; not checked against a 2017 source |
| EngineTorqueAtPeakHorsepower | 127.8 ft-lb | C | 146 hp x 5252 / 6000 rpm |
| AccelerationZeroToSixtyTime | 8.5 s | E | Not checked against a road test; typical for this crossover |
| EngineType | sparkIgnition | P | Gasoline engine |
