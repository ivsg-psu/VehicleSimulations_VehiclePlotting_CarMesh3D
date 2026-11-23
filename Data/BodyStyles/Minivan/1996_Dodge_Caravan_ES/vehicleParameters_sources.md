# Sources for vehicleParameters_1996_Dodge_Caravan_ES.mat

Vehicle: US 1996 Dodge Caravan ES, short-wheelbase minivan (third generation, NS), 3.3 L V6, 4-speed automatic, front-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row.

## The trim was inferred

The model's author (ActsOfDoge, "1996 Dodge Caravan" on Sketchfab) does not name a trim; the download arrived as `1996_Dodge_Caravan_XXX`. The model is 4.736 m long, the short-wheelbase Caravan (186.3 in), not the Grand Caravan (199.6 in). It has fog lamps and alloy wheels, and its tires are 0.69 m across, which fits a 215/65R16 (686 mm) and not the SE and LE's 215/65R15 (661 mm). For 1996, the 16 in alloy wheels came on the ES (autobytel.com used Caravan buyer's guide), as did fog lights (vincheck.info). Hence **Trim = ES, TrimStatus = E**. Pictures: `caravan_raw.png` and `caravan_frontside.png` in Claude's project folder (scratch\caravan).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 1996, Dodge, Caravan, ES | P (trim E) | Model title "1996 Dodge Caravan"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 1700 kg | P | 3,748 lb, Caravan III SWB 3.3 V6 automatic (auto-data.net); kbb.com lists 3,875 lb for a 1996 Caravan |
| MassCurbFrontAxle | 986 kg | E | Curb mass x 0.58, typical for a front-drive minivan |
| MassCurbRearAxle | 714 kg | C | Curb mass - front-axle mass |
| MassGross | 2454 kg | P | Gross weight (auto-data.net, cararac.com) |
| Ixx, Iyy, Izz (curb and gross) | 550, 2389, 2501 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this van's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 2.878 m | P | 113.3 in (consumerguide.com; auto-data.net 2878 mm) |
| DistancesLength | 4.733 m | P | 186.3 in (consumerguide.com; auto-data.net 4733 mm) |
| DistancesWidth | 1.920 m | P | 75.6 in (consumerguide.com; auto-data.net 1920 mm). Some sites list 76.8 in |
| DistancesWidthWithMirrors | 2.317 m | E | Not published. The model's full width over its body width (2.348 / 1.946) times the published width |
| DistancesHeight | 1.740 m | P | 68.5 in (consumerguide.com; auto-data.net) |
| DistancesGroundClearance | 0.140 m | P | 140 mm ride height (auto-data.net; cararac.com) |
| DistancesFrontTrack | 1.600 m | P | 1600 mm (auto-data.net; cararac.com) |
| DistancesRearTrack | 1.626 m | P | 1626 mm (auto-data.net; cararac.com) |
| DistancesFrontOverhang | 0.842 m | E | Not published. From the downloaded model's front axle and bumper, scaled to the published length |
| DistancesRearOverhang | 1.013 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.669 m | C | Wheelbase x 0.58 (the front share above) |
| DistancesCGAboveGround | 0.70 m | E | Not published; typical for a minivan of this height |
| TireSidewallMarkings | P215/65R16 | E | The 1996 ES size (kbb.com 1996 Grand Caravan trims: P215/65R16 on the top trim), matching the model's tire diameter |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.73 m | C | Half of the 37.6 ft turning diameter (kbb.com 1996 Caravan) |
| EngineDisplacement, EngineCylinders | 3.301 L, 6 | P | 3.3 L V6 (edmunds.com; auto-data.net 3301 cc). The ES could also have the 3.8 L |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 158 hp at 4,850 rpm | P | (edmunds.com 1996 Grand Caravan, the same engine) |
| EngineTorqueAtPeakHorsepower | 171.1 ft-lb | C | 158 hp x 5252 / 4850 rpm (peak torque 203 lb-ft at 3,250 rpm) |
| AccelerationZeroToSixtyTime | 10.5 s | E | Not checked against a road test; typical for this van |
| EngineType | sparkIgnition | P | Gasoline engine |
