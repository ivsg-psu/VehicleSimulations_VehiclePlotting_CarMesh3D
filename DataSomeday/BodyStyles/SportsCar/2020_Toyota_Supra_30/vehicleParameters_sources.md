# Sources for vehicleParameters_2020_Toyota_Supra_30.mat

Vehicle: US 2020 Toyota GR Supra 3.0, 2-door coupe (fifth generation, A90), 3.0 L turbocharged I-6, 8-speed automatic, rear-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row (the sites' own published specifications).

## The trim was inferred

The model's author (ActsOfDoge, "2020 Toyota Supra" on Sketchfab) does not name a trim; the download arrived as `2020_Toyota_Supra_XXX`. For 2020, Toyota sold the GR Supra as the 3.0 and 3.0 Premium grades and a Launch Edition (based on the 3.0 Premium). The Launch Edition has red mirror caps and 19 in forged matte-black wheels (Toyota pressroom, 2020 Supra launch release). The model's mirror caps are black and its wheels are two-tone machined, so it is not a Launch Edition. The 3.0 and 3.0 Premium differ mainly inside (screen, seats, head-up display) and share the 2020 exterior, wheels, dimensions, and powertrain (Toyota pressroom, "It's Back: 2020 GR Supra Ready for the Road"). So the base grade was taken: **Trim = 3.0 (ID part `30`), TrimStatus = E**, with the reasoning in `TrimSource`. The model's body is white (Absolute Zero, offered on all three). Pictures: `supra_raw.png` and `supra_closeups.png` in Claude's project folder (scratch\supra).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2020, Toyota, Supra, 3.0 | P (trim E) | Model title "2020 Toyota Supra"; trim inferred as above |
| TrimStatus, TrimSource | E; the reasoning above | E | vehicleParameters change request 16 |
| MassCurb, Mass | 1540.9 kg | C | 3,397 lb (Toyota pressroom, 2020 Supra product information; the same for all grades, kbb.com) |
| MassCurbFrontAxle, MassCurbRearAxle | 770.5 kg each | E | Half the curb mass: Toyota describes a near 50:50 weight balance; not checked against a published axle split |
| MassGross | 1814.8 kg | C | 4,001 lb gross weight (autoblog.com 2020 Supra 3.0 specifications; auto-data.net 1815 kg) |
| Ixx, Iyy, Izz (curb and gross) | 379, 1777, 1967 (curb); 446, 2093, 2317 (gross) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this car's dimensions (roll: width and height; pitch: length and height; yaw: length and width); gross by the gross/curb mass ratio |
| DistancesWheelbase | 2.469 m | P | 97.2 in (autoblog.com; conceptcarz.com 2469 mm; carsguide.com.au 2470 mm). The model's own wheelbase scales to 2.467 m |
| DistancesLength | 4.382 m | P | 172.5 in (Toyota pressroom) |
| DistancesWidth | 1.854 m | P | 73.0 in, without mirrors (Toyota pressroom; edmunds.com) |
| DistancesWidthWithMirrors | 2.027 m | E | 79.8 in, the "width" listed by iseecars.com (6.8 in over the published body width, so taken as with mirrors). The model's full width scales to 2.017 m |
| DistancesHeight | 1.293 m | P | 50.9 in (Toyota pressroom) |
| DistancesGroundClearance | 0.114 m | P | 4.5 in (Toyota pressroom; kbb.com) |
| DistancesFrontTrack | 1.595 m | P | 62.8 in (Toyota pressroom, tread width front) |
| DistancesRearTrack | 1.590 m | P | 62.6 in (Toyota pressroom, tread width rear) |
| DistancesFrontOverhang | 0.963 m | E | Not published. From the downloaded model's front axle and bumper (0.772 m), scaled to the published length |
| DistancesRearOverhang | 0.950 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.235 m | C | Half the wheelbase (the 50:50 balance above) |
| DistancesCGAboveGround | 0.45 m | E | Not published; typical for a low sports coupe |
| TireSidewallMarkings | {255/35ZR19 96Y, 275/35ZR19 100Y} (front, rear) | P | All 2020 grades (iseecars.com tire sizes; michelinman.com 2020 GR Supra fitment) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.20 m | C | Half of the 10.40 m kerb-to-kerb turning circle (carsguide.com.au; carexpert.com.au, 2020 Supra) |
| EngineDisplacement, EngineCylinders | 2.998 L, 6 | P | 3.0 L / 2998 cc turbocharged in-line 6 (Toyota pressroom; auto-data.net) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 335 hp at 5,000 rpm | P | 335 hp (Toyota pressroom), held from 5,000 to 6,500 rpm; the start of that range is used |
| EngineTorqueAtPeakHorsepower | 351.9 ft-lb | C | 335 hp x 5252 / 5000 rpm (the published peak torque is 365 lb-ft, 1,600 to 4,500 rpm) |
| AccelerationZeroToSixtyTime | 4.1 s | P | Toyota's figure for 2020 (kbb.com; Toyota pressroom, 2021 release: "3.9 seconds, from 4.1") |
| EngineType | sparkIgnition | P | Gasoline engine |
