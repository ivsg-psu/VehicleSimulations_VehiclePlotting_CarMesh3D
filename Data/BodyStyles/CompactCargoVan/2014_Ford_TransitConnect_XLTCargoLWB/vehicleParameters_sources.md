# Sources for vehicleParameters_2014_Ford_TransitConnect_XLTCargoLWB.mat

Vehicle: 2014 Ford Transit Connect XLT Cargo Van, long wheelbase (LWB).

The downloaded model in this folder ("2014 Ford Transit Connect Cargo" by tonielpro520, CC-BY) is the LWB cargo van: its wheel centers are 3.04 m apart (LWB: 3.063 m; SWB: 2.662 m), and it has no rear side windows.

Status: **P** = published value (converted to SI); **C** = calculated from published values; **E** = estimate (check, or replace with better data).

| Field | Value | Status | Source / method |
|---|---|---|---|
| Year, Make, Model, Trim | 2014, Ford, Transit Connect, XLT Cargo Van LWB | P | XLT, as chosen by S. Brennan (XL and XLT LWB cargo vans share these dimensions and weights) |
| MassCurb, Mass | 1641.1 kg | P | 3,618 lb base curb weight, LWB cargo (cars.com, 2014 LWB XLT; motormatchup.com, 2014 XL Cargo Van LWB) |
| MassCurbFrontAxle | 982.9 kg | P | 2,167 lb (cars.com, 2014 LWB XLT) |
| MassCurbRearAxle | 658.2 kg | P | 1,451 lb (cars.com, 2014 LWB XLT) |
| MassGross | 2390.4 kg | P | 5,270 lb GVWR (autoblog.com, 2015 XL Cargo Van LWB) |
| DistancesWheelbase | 3.063 m | P | 120.6 in (Ford 2017-18 vehicle guide; kbb.com; autoblog.com) |
| DistancesLength | 4.818 m | P | 189.7 in (Ford 2017-18 vehicle guide) |
| DistancesWidth | 1.834 m | P | 72.2 in without mirrors |
| DistancesWidthWithMirrors | 2.136 m | P | 84.1 in (kbb.com; Ford vehicle guide) |
| DistancesHeight | 1.849 m | P | 72.8 in, LWB (Ford 2017-18 vehicle guide; edmunds.com) |
| DistancesGroundClearance | 0.152 m | P | 6.0 in (autoblog.com 2015 LWB; theautochannel.com) |
| DistancesFrontTrack | 1.567 m | P | 61.7 in (edmunds.com, 2014 LWB XLT). Other sources give 61.4 in; the larger value is used, to be conservative |
| DistancesRearTrack | 1.585 m | P | 62.4 in (iseecars.com). Other sources give 61.7 in; the larger value is used, to be conservative |
| DistancesFrontOverhang | 0.890 m | E | Not published. Total overhang (4.818 - 3.063 = 1.755 m) split in the same ratio as in the downloaded model (front 0.820 m, rear 0.797 m) |
| DistancesRearOverhang | 0.865 m | C | Length - wheelbase - front overhang |
| DistancesCGFromRearAxle | 1.835 m | C | Wheelbase x front-axle mass / curb mass |
| DistancesCGAboveGround | 0.68 m | E | Not published; typical for a tall van of this height |
| TireSidewallMarkings | P215/55HR16 | P | XL and XLT cargo vans (cars.com; kbb.com) |
| TireFrontCorneringCoefficient | 11 1/rad | E | Typical value for most vehicles (S. Brennan) |
| TireRearCorneringCoefficient | 14 1/rad | E | Typical value for most vehicles (S. Brennan) |
| MinimumTurnRadius | 6.10 m | C | Half of the 40.0 ft LWB turning diameter (truecar.com) |
| Ixx, IxxCurb / IxxGross | 536 / 767 kg-m^2 | E | Prius values scaled by mass and by the size of the van (radius of gyration scaled by the width-height diagonal) |
| Iyy, IyyCurb / IyyGross | 2416 / 3085 kg-m^2 | E | Same method, length-height diagonal |
| Izz, IzzCurb / IzzGross | 2462 / 3198 kg-m^2 | E | Same method, length-width diagonal |
| EngineDisplacement, EngineCylinders | 2.5 L, 4 | P | 2.5 L I-4 |
| EnginePeakHorsepower, EngineSpeedAtPeakHorsepower | 169 hp, 6000 rpm | P | (autotk.com; truecar.com) |
| EngineTorqueAtPeakHorsepower | 147.9 ft-lb | C | 169 hp x 5252 / 6000 rpm. (Peak torque is 171 lb-ft at 4500 rpm) |
| AccelerationZeroToSixtyTime | 8.9 s | P | Range 8.5 to 9.7 s across sources (autotk.com; motormatchup.com) |
| EngineType, EngineHybridEngineType | sparkIgnition, (none) | P | 2.5 L I-4 gasoline engine; not a hybrid (added 2026-11-20) |

The text fields (`_Text`, `_PrintFormat`, `_AllowableRange`, `_Units`) were copied from the 2013 Prius file, with the front-overhang description corrected to "from the center of the front axle to the front-most location of the front bumper".
