# Sources for vehicleParameters_1994_Mazda_MX5_MiataBase.mat

Vehicle: US 1994 Mazda MX-5 Miata (first generation, NA), 1.8 L I-4, base, with a hardtop fitted (as in the 3D model).

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-21 (a draft for Sean to check) from the web pages named in each row.

**The model:** "Mazda MX5 Miata" by karimijannes0 on Sketchfab, **CC Attribution** (the credit line is in LICENSE.txt and must go with any picture of this vehicle). Its title names no year or trim; the folder name (1994, base) was chosen at download. Its root node turns the car 28.5 degrees off the axes, so the vehicle script uses `mazda_mx5_miata_aligned.obj`, Blender's conversion of the download turned back onto the axes.

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 1994, Mazda, MX5, MiataBase | E | Folder name at download; TrimStatus 'E' |
| MassCurb, Mass | 1040 kg | P | 2,293 lb, 1994 base convertible (motormatchup.com) |
| MassCurbFrontAxle | 541 kg | E | Curb mass x 0.52 (a near 50/50 roadster) |
| MassCurbRearAxle | 499 kg | C | Curb mass - front-axle mass |
| MassGross | 1290 kg | E | Curb mass + 250 kg (two people and luggage) |
| Ixx, Iyy, Izz (curb and gross) | from the 2009 Fit Sport | E | Its values scaled by mass and by the squares of this car's dimensions |
| DistancesWheelbase | 2.266 m | P | 89.2 in (kbb.com; edmunds.com) |
| DistancesLength | 3.947 m | P | 155.4 in, US bumpers (kbb.com; edmunds.com) |
| DistancesWidth | 1.674 m | P | 65.9 in (edmunds.com, without mirrors) |
| DistancesWidthWithMirrors | 1.944 m | E | Width + 0.27 m (the usual rule here) |
| DistancesHeight | 1.224 m | P | 48.2 in (edmunds.com; iseecars.com) |
| DistancesGroundClearance | 0.114 m | P | 4.5 in (kbb.com; edmunds.com) |
| DistancesFrontTrack | 1.410 m | P | 55.5 in / 1410 mm, 1.8 L (carsales.com.au 1994; carexpert.com.au) |
| DistancesRearTrack | 1.430 m | P | 56.3 in / 1430 mm, 1.8 L (carsales.com.au 1994; carexpert.com.au) |
| DistancesFrontOverhang | 0.798 m | E | 47.5% of the total overhang (length - wheelbase): the share in the downloaded model |
| DistancesRearOverhang | 0.883 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.178 m | C | Wheelbase x 0.52 |
| DistancesCGAboveGround | 0.46 m | E | Typical for a low roadster |
| TireSidewallMarkings | 185/60R14 82H | P | 14 in wheels (mossmiata.com 1994 specifications) |
| TireFrontCorneringCoefficient, TireRearCorneringCoefficient | 11, 14 1/rad | E | Typical values (S. Brennan) |
| MinimumTurnRadius | 4.57 m | C | Half of the 30 ft turning diameter (kbb.com) |
| EngineDisplacement, EngineCylinders | 1.839 L, 4 | P | 1.8 L in-line 4 (mossmiata.com; auto-data.net 1840 cc) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 128 hp at 6,500 rpm | P (rpm E) | 128 hp (kbb.com; motormatchup.com) |
| EngineTorqueAtPeakHorsepower | 103.4 ft-lb | C | 128 hp x 5252 / 6500 rpm |
| AccelerationZeroToSixtyTime | 8.5 s | P | (motormatchup.com) |
| EngineType | sparkIgnition | P | Gasoline engine |
