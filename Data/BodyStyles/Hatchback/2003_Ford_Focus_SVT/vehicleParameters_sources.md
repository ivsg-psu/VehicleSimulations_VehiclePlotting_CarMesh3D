# Sources for vehicleParameters_2003_Ford_Focus_SVT.mat

Vehicle: US 2003 Ford SVT Focus, 3-door hatchback (first generation), 2.0 L I-4 (Duratec ST), 6-speed manual, front-wheel drive.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

Values gathered by Claude on 2026-11-22 (a draft for Sean to check) from the web pages named in each row.

## The trim

The model's title on Sketchfab is "2003 Ford Focus SVT" (ActsOfDoge): **Trim = SVT, TrimStatus = P**. It is the 3-door; for 2003 the SVT also came as a 5-door (theautochannel.com). Picture: `focussvt_raw.png` in Claude's project folder (scratch\focussvt).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2003, Ford, Focus, SVT | P | Model title |
| TrimStatus, TrimSource | P; the model's title | P | vehicleParameters change request 16 |
| MassCurb, Mass | 1247.4 kg | C | 2,750 lb (theautochannel.com 2003 SVT Focus road test; autopadre.com lists 2,551 lb, kbb.com 2,593 lb) |
| MassCurbFrontAxle | 773.4 kg | E | Curb mass x 0.62, typical for a front-drive hatchback |
| MassCurbRearAxle | 474.0 kg | C | Curb mass - front-axle mass |
| MassGross | 1647.4 kg | E | Curb mass + 400 kg (gross weight not found) |
| Ixx, Iyy, Izz (curb and gross) | 296, 1398, 1486 (curb) kg-m^2 | E | The 2009 Fit Sport's values, scaled by mass and by the squares of this car's dimensions; gross by the gross/curb mass ratio |
| DistancesWheelbase | 2.616 m | P | 103.0 in (theautochannel.com; iseecars.com) |
| DistancesLength | 4.270 m | P | 168.1 in (theautochannel.com; iseecars.com) |
| DistancesWidth | 1.699 m | P | 66.9 in, without mirrors (autopadre.com; auto-data.net 1699 mm) |
| DistancesWidthWithMirrors | 1.982 m | E | The model's full width over its body width (1.167) times the published width |
| DistancesHeight | 1.430 m | P | 56.3 in (iseecars.com; autopadre.com) |
| DistancesGroundClearance | 0.13 m | E | Not found; typical for this car |
| DistancesFrontTrack | 1.494 m | P | 58.8 in (carspecs.us; auto-data.net 1494 mm) |
| DistancesRearTrack | 1.486 m | P | 58.5 in (carspecs.us; auto-data.net 1486 mm) |
| DistancesFrontOverhang | 0.880 m | E | Not published. From the downloaded model's front axle and bumper (the model is at full size) |
| DistancesRearOverhang | 0.774 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.622 m | C | Wheelbase x 0.62 (the front share above) |
| DistancesCGAboveGround | 0.50 m | E | Not published; typical for a hatchback |
| TireSidewallMarkings | P215/45ZR17 | P | (autopadre.com 2003 Focus SVT) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 5.23 m | E | Half of the 34.3 ft turning circle of the 2003 Focus (edmunds.com; not the SVT's own figure) |
| EngineDisplacement, EngineCylinders | 2.0 L, 4 | P | (cars.com 2003 Focus SVT: 2.0L/121) |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 170 hp at 7,000 rpm | P | (cars.com; kbb.com; theautochannel.com) |
| EngineTorqueAtPeakHorsepower | 127.5 ft-lb | C | 170 hp x 5252 / 7000 rpm (peak torque 145 lb-ft at 5,500 rpm) |
| AccelerationZeroToSixtyTime | 7.3 s | E | Not checked against a road test; typical for this car |
| EngineType | sparkIgnition | P | Gasoline engine |
