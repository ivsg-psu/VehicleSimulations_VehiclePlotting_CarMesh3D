# Sources for vehicleParameters_2011_Ford_Fusion_Sport.mat

Vehicle: US 2011 Ford Fusion Sport, mid-size sedan (first generation, 2010 refresh), 3.5 L V6, 6-speed automatic, front-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row.

## The trim was inferred

The model's author (ActsOfDoge, "2011 Ford Fusion" on Sketchfab) does not name a trim; the download arrived as `2011_Ford_Fusion_XXX`. The model has dual exhaust outlets (one each side) and five-spoke wheels about 0.50 m across the rim, 18 in wheels. For 2011, the 225/45VR18 tires were standard only on the Sport (truedelta.com 2011 Fusion tires by trim), which also had the 3.5 L V6 and dual exhaust. Hence **Trim = Sport, TrimStatus = E**. Pictures: `fusion_materials.png` and `fusion_rear_wheel.png` in Claude's project folder (scratch\fusion).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2011, Ford, Fusion, Sport | P (trim E) | Model title "2011 Ford Fusion"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 1628.8 kg | C | 3,591 lb, Sport FWD (edmunds.com) |
| MassCurbFrontAxle | 1009.9 kg | E | Curb mass x 0.62, typical for a front-drive V6 sedan |
| MassCurbRearAxle | 618.9 kg | C | Curb mass - front-axle mass |
| MassGross | 2217.8 kg | E | Curb mass + 589 kg, the SEL's published gross-minus-curb (auto123.com: 2029 - 1440 kg) |
| Ixx, Iyy, Izz (curb and gross) | 428, 2298, 2462 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this car's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 2.728 m | P | 107.4 in (Ford 2010 Fusion technical specifications) |
| DistancesLength | 4.841 m | P | 190.6 in (Ford technical specifications) |
| DistancesWidth | 1.834 m | P | 72.2 in, excluding mirrors (Ford technical specifications) |
| DistancesWidthWithMirrors | 2.035 m | P | 80.1 in, including mirrors (Ford technical specifications; kbb.com) |
| DistancesHeight | 1.445 m | P | 56.9 in (Ford technical specifications) |
| DistancesGroundClearance | 0.135 m | P | 5.3 in (autobytel.com; autopadre.com, Sport) |
| DistancesFrontTrack | 1.567 m | P | 61.7 in (Ford technical specifications) |
| DistancesRearTrack | 1.557 m | P | 61.3 in (Ford technical specifications) |
| DistancesFrontOverhang | 1.011 m | E | Not published. From the downloaded model's front axle and bumper, scaled to the published length |
| DistancesRearOverhang | 1.102 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.691 m | C | Wheelbase x 0.62 (the front share above) |
| DistancesCGAboveGround | 0.53 m | E | Not published; typical for a mid-size sedan |
| TireSidewallMarkings | P225/45VR18 | P | Sport (truedelta.com; auto123.com lists 225/45R18 as the option on other trims) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.72 m | C | Half of the 37.5 ft curb-to-curb turning circle (Ford technical specifications; cars.com lists 39 ft) |
| EngineDisplacement, EngineCylinders | 3.5 L, 6 | P | 3.5 L V6, Sport (kbb.com: 263 hp) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 263 hp at 6,250 rpm | P (rpm E) | 263 hp (kbb.com); the engine speed was not checked against a Ford source |
| EngineTorqueAtPeakHorsepower | 221.0 ft-lb | C | 263 hp x 5252 / 6250 rpm |
| AccelerationZeroToSixtyTime | 6.8 s | E | Not checked against a road test; typical for this car |
| EngineType | sparkIgnition | P | Gasoline engine |
