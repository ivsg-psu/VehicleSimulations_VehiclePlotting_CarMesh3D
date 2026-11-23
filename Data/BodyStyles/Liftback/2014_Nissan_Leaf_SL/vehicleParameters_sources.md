# Sources for vehicleParameters_2014_Nissan_Leaf_SL.mat

Vehicle: US 2014 Nissan Leaf SL, 5-door electric hatchback (first generation, ZE0), 80 kW motor, 24 kWh battery, front-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-22 (a draft for Sean to check) from the web pages named in each row.

## The trim was inferred

The model's author (ActsOfDoge, "2014 Nissan Leaf" on Sketchfab) does not name a trim; the download arrived as `2014_Nissan_Leaf_XXX`. The model has alloy wheels with a rim about 0.44 m across (17 in is 0.43 m) and fog lamps in the front bumper. For 2014, the S had 16 in steel wheels, the SV 16 in alloys (both 205/55R16), and the SL 17 in alloys with 215/50R17 tires (Nissan 2014 Leaf press kit; edmunds.com trims) and fog lamps. The model's tire is 0.634 m across, between the 16 in (0.632 m) and 17 in (0.647 m) sizes, so it does not decide. Hence **Trim = SL, TrimStatus = E**. Picture: `leaf_raw.png` in Claude's project folder (scratch\leaf).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2014, Nissan, Leaf, SL | P (trim E) | Model title "2014 Nissan Leaf"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 1508.6 kg | C | 3,326 lb, SL (edmunds.com; iseecars.com) |
| MassCurbFrontAxle | 875.0 kg | E | Curb mass x 0.58, typical for a front-drive hatchback with an underfloor battery |
| MassCurbRearAxle | 633.6 kg | C | Curb mass - front-axle mass |
| MassGross | 1901.9 kg | C | 4,193 lb gross weight, SL (edmunds.com) |
| Ixx, Iyy, Izz (curb and gross) | 402, 1847, 1948 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this car's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 2.700 m | P | 106.3 in (Nissan 2014 Leaf press kit) |
| DistancesLength | 4.445 m | P | 175.0 in (Nissan press kit) |
| DistancesWidth | 1.770 m | P | 69.7 in (Nissan press kit) |
| DistancesWidthWithMirrors | 1.966 m | P | 77.4 in (evspecifications.com) |
| DistancesHeight | 1.549 m | P | 61.0 in (Nissan press kit) |
| DistancesGroundClearance | 0.160 m | P | 6.3 in (edmunds.com; autopadre.com) |
| DistancesFrontTrack | 1.539 m | P | 60.6 in (iseecars.com; carspecs.us) |
| DistancesRearTrack | 1.534 m | P | 60.4 in (edmunds.com; carspecs.us) |
| DistancesFrontOverhang | 0.955 m | E | Not published. From the downloaded model's front axle and bumper (the model is at full size) |
| DistancesRearOverhang | 0.790 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.566 m | C | Wheelbase x 0.58 (the front share above) |
| DistancesCGAboveGround | 0.52 m | E | Not published; the battery under the floor keeps it low |
| TireSidewallMarkings | P215/50VR17 | P | SL (Nissan press kit; autopadre.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.21 m | C | Half of the 34.2 ft turning circle (edmunds.com; autopadre.com) |
| EngineDisplacement, EngineCylinders | NaN, NaN | P | Electric: no engine |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 107 hp at 2,730 rpm | P (rpm E) | 107 hp (kbb.com; cars.com); the motor's peak power is held over a wide speed range, and its start is used |
| EngineTorqueAtPeakHorsepower | 205.8 ft-lb | C | 107 hp x 5252 / 2730 rpm (published peak torque: 187 lb-ft, velocityjournal.com; truedelta.com lists 207) |
| AccelerationZeroToSixtyTime | 10.2 s | E | Not checked against a road test; typical for this car |
| EngineType | electric | P | Battery electric (no engine) |
