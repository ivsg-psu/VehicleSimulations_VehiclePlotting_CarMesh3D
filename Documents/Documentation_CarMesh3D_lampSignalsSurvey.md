# Lamp signals survey: what production vehicles switch, and what CarMesh3D should call it

*Written by Claude, 2026-11-26 16:53 to 16:56 (clock checked), for Sean's request of 13:57 ("capture all of the signals out there and group them into common naming conventions ... a template that lists our findings"), split into exterior and interior signals (Sean, 13:57). Item N1 in the answer queue. Names follow the project's conventions (`Documentation_CarMesh3D_namingTable.md`, section 3): a signal is what is switched on at one moment; a lamp is the hardware it lights.*

## 0. How to read this

CarMesh3D keeps two things apart (README, "Switchable lights"):

- a **lamp kind** is hardware: what a group of faces *is* (`headlamp`, `tailBrakeLamp`, ...; `fcn_CarMesh3D_lampTypes`);
- a **signal** is what the driver or the vehicle switches on (`LowBeam`, `Brake`, ...; `fcn_CarMesh3D_lampSignals`), and each vehicle's lamp-to-function matrix says which lamps each signal lights, and how brightly.

So a new piece of hardware (a center high-mounted stop lamp, a roof clearance lamp) is a new **lamp kind** lit by an existing signal; only a new *reason* to switch lamps is a new **signal**. Flashing, sequential sweeps and emergency patterns are **time patterns** of a signal, which the animation makes (as AnimateCar3D blinks the turn signals now), not signals of their own.

In the tables, **Status** says where CarMesh3D is today: *have* (a signal or lamp kind that exists), *new* (proposed here), or *pattern* (a time pattern of an existing signal).

## 1. Exterior signals

### 1.1 Signals every road vehicle has (US: FMVSS No. 108; UN/Europe: UN R48)

| Signal (proposed name) | Status | Lights (lamp kinds) | Color | Steady or flashing | Notes and sources |
|---|---|---|---|---|---|
| `LowBeam` | have | headlamp (lower beam) | white | steady | Required on every class. |
| `HighBeam` | have | headlamp (upper beam), highBeamLamp | white | steady | Adaptive driving beam (ADB: a high beam that shades other road users) has been allowed in the US since the 2022 amendment; for CarMesh3D it is a way the beam is drawn, not a new signal. |
| `Running` | have | runningLamp (DRL), markerLamp | white | steady | Permitted in the US, required in Canada since 1990 (CMVSS 108), required in the EU. |
| `Parking` | have | parking lamps, tail lamps (dim), licensePlateLamp, markerLamp | white or amber front, red rear | steady | US parking lamps are required only below 80 in (2032 mm) overall width. |
| `Tail` | have | tailBrakeLamp (dim), licensePlateLamp, markerLamp, clearance and identification lamps | red | steady | On with the headlamps or parking lamps. |
| `Brake` | have | tailBrakeLamp (bright), **highMountStopLamp** (CHMSL, new kind) | red | steady | The CHMSL gives a steady stop warning through intervening vehicles; it may not be made to flash as a hazard lamp in the US. |
| `TurnLeft`, `TurnRight` | have | turnSignalLamp (front, rear, side repeaters) | amber (rear red or amber in the US) | flashing (pattern) | Sequential sweeps (Audi, Ford Mustang) are a pattern. |
| `Hazards` | have | every turnSignalLamp | amber | flashing, in phase | Required on every vehicle except trailers and motorcycles in the US; a driver-controlled device that flashes all turn signal lamps together. |
| `Backup` | have | backupLamp | white | steady | Only with the ignition on and reverse gear engaged. |
| `Fog` | have | fogLamp (front) | white or selective yellow | steady | Optional. |
| `Reflectors` | have (0 to 1) | reflector, conspicuity tape | red, amber, white | (outside light) | Not powered: lit by other vehicles' lamps. |
| `RearFog` | **new** | **rearFogLamp** (new kind) | red | steady | Required in Europe (UN R48), rare in the US; gives a red signal brighter than the rear position lamps in dense fog. |
| `EmergencyBrake` | **new** | tailBrakeLamp, highMountStopLamp (flashing), or the hazard lamps (some makers) | red (or amber) | flashing (pattern) | UN R48 lets the stop lamps flash under emergency braking (the emergency stop signal, ESS), activated and deactivated automatically above about 50 km/h; Kia's ESS triggers above 55 km/h at more than 7 m/s² or with ABS; Honda's version flashes the hazard lamps instead. A distinct signal because the vehicle, not the driver, switches it, and it overrides steady Brake. |

### 1.2 Signals of particular equipment or vehicle classes

| Signal (proposed name) | Status | Lights (lamp kinds) | Color | Steady or flashing | Who has it, and sources |
|---|---|---|---|---|---|
| `Cornering` (left and right: `CorneringLeft`, `CorneringRight`) | **new** | **corneringLamp** | white | steady | UN R119 cornering lamps (also on some US cars): lit on the side of a turn at low speed, from the turn signal or the steering. Could instead be the turn signals plus speed in each vehicle's matrix; kept as a signal because it is lit steady, not flashing. |
| `DoorOpen` | **new** | **puddleLamp** (under mirrors and doors), courtesy lamps in the doors | white | steady | Most current cars; UN R48 calls them courtesy lamps. |
| `Welcome` | **new** | puddleLamp, headlamp and tail animations, illuminated logo | white (logo colors) | pattern | The approach / unlock "welcome" lighting. The lock and unlock flash of the turn signals (UN R48's "answer-back signal") is a short Hazards pattern, not a signal. |
| `Cargo` | **new** | **cargoLamp** (bed and cargo lamps) | white | steady | FMVSS No. 108 defines a cargo lamp as one on an MPV, truck or bus for loading and unloading cargo: our pickups (F-150, Frontier, Raptor) and vans (Transit Connect, HiAce). |
| `Work` | **new** | **workLamp** (spot and flood lamps on work trucks, tractors) | white | steady | Under discussion for UN R48 (2025 work-lamp proposals); not for use while driving on the road. |
| `Beacon` | **new** | **beaconLamp** (rotating or LED amber beacons, light bars on tow, utility and maintenance trucks) | amber | flashing (pattern) | Outside FMVSS 108; set by state law, which reserves red and blue for emergency vehicles (California allows amber warning lamps for tow trucks and other permitted vehicles). |
| `Emergency` | **new** | **emergencyLamp** (light bars, grille and corner flashers), headlamp flashers ("wig-wag") | red, blue, white, amber (by state and service) | flashing (patterns) | Police, fire and ambulance. Colors are state law: Washington requires at least one red lamp on emergency vehicles and one blue lamp on police vehicles; Iowa puts red on the driver's side and blue on the passenger's side of a light bar. 360-degree warning lamps meet SAE J845. Patterns (alternating, rotating, quad flash) are animation patterns. A UK or EU vehicle uses blue. |
| `SchoolAmber`, `SchoolRed` | **new** | **schoolBusLamp** (amber and red, top front and top rear), **stopArmLamp** (on the stop arm) | amber, red | alternating flash (pattern) | FMVSS No. 108 requires either four red lamps, or four red and four amber; the amber lamps are switched on by hand and go off, with the red ones coming on automatically, when the entrance door opens. They alternate at 60 to 120 flashes a minute. The stop arm (FMVSS No. 131) carries at least two red lamps on each side, lit with the red lamps. |
| `Automated` | **new** | **adsMarkerLamp** | turquoise (blue-green) | steady | SAE J3134 (2019, revised 2025): marker lamps that show an automated driving system is driving. Mercedes-Benz DRIVE PILOT uses them under permits in California, Nevada and (2025, for testing) Germany. NHTSA proposed in 2026 to allow and standardize ADS marker lamps in FMVSS No. 108. |
| `Charging` | **new** | **chargePortLamp** (status lights at the charge port, some front light bars) | green, blue, white, amber (maker's choice) | steady or pulsing | EVs (Leaf, Prius Prime-type plug-ins): shows charging state while parked. Not regulated as a lamp; a parked-vehicle signal. |

### 1.3 Lamp kinds needed by wide and heavy vehicles (lit by existing signals)

These need no new signal: they are lit by `Tail`, `Parking` or `Running`, but the lamp kinds are new.

| Lamp kind (proposed) | Lit by | Color | Who has them, and sources |
|---|---|---|---|
| `clearanceLamp` | Tail, Parking | amber front, red rear | Required on vehicles 80 in (2032 mm) or wider, front and rear, to show the overall width; a truck tractor needs no rear ones. |
| `identificationLamp` (3 in a row) | Tail, Parking | amber front, red rear | Required on vehicles 80 in or wider: three lamps on the centerline, 6 to 12 in apart, high on the vehicle. In our folders: the **2010 Ford F-150 Raptor** (2.19 m wide: its three amber grille lamps) and the **2021 Chevrolet Suburban** (2.06 m: check its roof). The 2015 F-150 (2.03 m) is just under. |
| `markerLamp` (side, have) and intermediate side markers | Tail, Parking, Running | amber front and middle, red rear | Intermediate side markers only on vehicles 30 ft or longer (trailers). |
| `conspicuityTape` (a reflector kind) | Reflectors | red and white, white high at the rear | Trailers 80 in or wider and over 10,000 lb GVWR (since 1993). |

### 1.4 Motorcycles

Motorcycles need a headlamp, tail lamp, stop lamp, turn signals, license plate lamp and red and amber reflex reflectors (FMVSS No. 108), and no hazard flasher. The headlamp may modulate (240 ± 40 cycles a minute, only by day): a `LowBeam`/`HighBeam` pattern, not a new signal. No new signals.

### 1.5 Illuminated logos and light bars

Front and rear light bars across the vehicle, and lit maker logos, are lamp kinds lit by `Running`, `Parking` or `Tail` (or `Welcome`). UN rules were amended (R48 and R148) to allow lit maker logos only as part of light-signalling devices; Australia treats a lit badge as not a lamp when it is lit only with the front position lamps. Proposed lamp kind: `logoLamp` (and light bars as `runningLamp` or `tailBrakeLamp` faces, as today).

## 2. Interior signals

Interior lights are not signals to other road users, so they are not in FMVSS No. 108 or UN R48's lists of lamps, and their names follow what makers and suppliers call them: functional lights (dome, map or reading, courtesy, glove box, trunk) and ambient or accent lighting (footwell, door panels, cup holders, dash edges).

| Signal (proposed name) | Lights (interior lamp kinds) | Values | Notes |
|---|---|---|---|
| `Dome` | **domeLamp** | 0/1 | The main ceiling light; on with a door open or by its switch. |
| `MapLeft`, `MapRight` (and `ReadingRear`) | **mapLamp**, **readingLamp** | 0/1 | Focused task lights over the front seats (and the rear). |
| `DoorOpen` (shared with exterior 1.2) | **courtesyLamp** (door panels, sills, footwells) | 0/1 | Entry and exit lighting; one signal lights both the exterior puddle lamps and these. |
| `Footwell` | **footwellLamp** | 0 to 1 | Often part of the ambient lighting. |
| `Ambient` | **ambientLamp** (strips in the dash, doors, console) | 0 to 1 (dimming), plus a color | The color is a vehicle setting, not a signal; a signal of brightness only. |
| `Instruments` | **instrumentLamp**, **displayLamp** (cluster, center screen) | 0 to 1 | Lit whenever the vehicle is on; dimmed at night with the headlamps (so the matrix can tie it to `LowBeam`). |
| `TrunkOpen` | **trunkLamp** / **cargoAreaLamp** | 0/1 | Trunk or cargo-area light, on while the lid is open. |
| `GloveBoxOpen` | **gloveBoxLamp** | 0/1 | Small; probably below what a sparse mesh shows. |

Interior lights matter to CarMesh3D only at night and through the glass (`LabelFaceInterior`: seats, steering wheel, console). Proposal: keep them in a structure of their own, **`InteriorSignals`**, beside `Signals`, so the exterior lamp-to-function matrix (and AnimateCar3D's motion files) stay as they are, and a vehicle with no interior faces ignores them.

## 3. Our vehicles, by class

All 35 vehicles in `Data/BodyStyles` and `DataSomeday/BodyStyles` are passenger cars, SUVs, pickups and vans under FMVSS No. 108's light-vehicle rules, so the 11 signals CarMesh3D has (section 1.1, *have*) cover what their lamps do. What the survey adds for them:

| Vehicles | Width (from the vehicle files) | Extra lamp kinds | Extra signals worth having |
|---|---|---|---|
| Sedans, coupes, hatchbacks, wagons, crossovers (Camry, Accord, Civic, Corolla, Fusion, Fit, Focus, Golf, MX-5, Mustang, Supra, Prius, Leaf, RAV4, CR-V, CX-3, Outback, V60) | 1.67 to 1.89 m | highMountStopLamp; puddleLamp on newer ones; logoLamp | `EmergencyBrake`, `DoorOpen`, `RearFog` (European-market models: V60, Golf), `Charging` (Leaf, Prius plug-ins) |
| Full-size SUVs (2014 Expedition 2.00 m, 2016 Explorer 2.00 m, **2021 Suburban 2.06 m**) | Suburban 80 in or wider | Suburban: clearanceLamp, identificationLamp (check its photos) | as above, plus `Cargo` |
| Pickups (1999 F-150 2.01 m, 2015 F-150 2.03 m, Frontier 1.85 m, **2010 Raptor 2.19 m**) | Raptor (and just possibly the 2015 F-150) 80 in or wider | Raptor: identificationLamp (the three amber grille lamps), clearanceLamp; all: cargoLamp (bed lamp), highMountStopLamp | `Cargo` |
| Vans (Transit Connect 1.83 m, HiAce 1.70 m, Caravan 1.92 m, generic cargo vans) | under 80 in | cargoLamp | `Cargo`, `DoorOpen` |

### Exemplars outside our folders (one per class, for the template)

| Class | Example | What it adds |
|---|---|---|
| Tractor-trailer | a Class 8 tractor with a 53 ft van trailer | clearanceLamp, identificationLamp (tractor front only; the tractor needs no rear clearance or identification lamps), intermediate side markers, conspicuity tape; a combination with any vehicle 80 in or wider shows three identification lamps at the rear. |
| School bus | a Type C school bus | `SchoolAmber`, `SchoolRed`, stopArmLamp; amber and red lamps alternate. |
| Emergency vehicle | a police SUV, an ambulance | `Emergency` (red, blue, white, by state), headlamp flashers. |
| Work truck | a utility or tow truck | `Beacon` (amber), `Work`. |
| Motorcycle | any road motorcycle | no new signals; headlamp modulation as a pattern. |
| EV with a light bar, ADS vehicle | a Mercedes EQS with DRIVE PILOT, a robotaxi | logoLamp and light bars; `Automated` (turquoise ADS marker lamps); `Charging`. |

## 4. Template: the signal lists for the mesh

What `fcn_CarMesh3D_lampSignals` (exterior) and a new `fcn_CarMesh3D_interiorSignals` would list. Tiers say what to add first; each tier is one more set of matrix columns and lamp kinds, read as 0 (off) by a vehicle made before it (as the matrix already does for a new signal).

**Tier 1, have (11):** `LowBeam`, `HighBeam`, `Running`, `Parking`, `TurnLeft`, `TurnRight`, `Tail`, `Brake`, `Backup`, `Fog`, `Reflectors` (and `Hazards`, the two turn signals together).

**Tier 2, every passenger vehicle (5):** `RearFog`, `EmergencyBrake`, `DoorOpen`, `Cargo`, `Automated`; lamp kinds `highMountStopLamp`, `rearFogLamp`, `puddleLamp`, `cargoLamp`, `adsMarkerLamp`, `logoLamp`, `clearanceLamp`, `identificationLamp`.

**Tier 3, special vehicles (7):** `Cornering` (left/right), `Welcome`, `Charging`, `Beacon`, `Work`, `Emergency`, `SchoolAmber`, `SchoolRed`; lamp kinds `corneringLamp`, `chargePortLamp`, `beaconLamp`, `workLamp`, `emergencyLamp`, `schoolBusLamp`, `stopArmLamp`.

**Interior (`InteriorSignals`):** `Dome`, `MapLeft`, `MapRight`, `ReadingRear`, `DoorOpen` (shared), `Footwell`, `Ambient` (0 to 1), `Instruments` (0 to 1), `TrunkOpen`, `GloveBoxOpen`; lamp kinds `domeLamp`, `mapLamp`, `readingLamp`, `courtesyLamp`, `footwellLamp`, `ambientLamp`, `instrumentLamp`, `displayLamp`, `trunkLamp`, `gloveBoxLamp`.

**Patterns, not signals (for AnimateCar3D):** turn-signal and hazard blinking (have), sequential turn sweeps, the lock/unlock answer-back flash, `EmergencyBrake` flashing (2 to 7 Hz), school bus alternation, emergency light-bar patterns, beacon rotation, motorcycle headlamp modulation.

Each new signal, when it is added, gets its paragraph in the naming table (convention C9) and a motion-file column `signal<Name>` (Q96).

## 5. Questions this raises (for Sean, when the work comes up)

1. **Tiers:** add tier 2 now (it touches every vehicle's matrix and the motion files: five more columns), or wait until a vehicle needs it?
2. **Interior:** a separate `InteriorSignals` structure (proposed), or interior fields in `Signals`?
3. **Emergency colors:** one `Emergency` signal with the colors set per vehicle (the matrix gives each lamp its color), or a signal per color (`EmergencyRed`, `EmergencyBlue`)? The first keeps the list short; state laws differ by color.
4. **Wide vehicles:** label the Raptor's three grille lamps (and the Suburban's roof lamps, if it has them) as `identificationLamp` now?

## Sources

- FMVSS No. 108, 49 CFR 571.108 (Cornell LII and eCFR; govinfo CFR 2000, 2002); NHTSA interpretations on school bus signal lamps, hazard warning signals, CHMSL and motorcycle headlamp modulation; NHTSA ADB final rule (Federal Register, 2022-02-22) and its 2024 response to petitions; NHTSA 2026 proposed modernization of FMVSS No. 108 (ADS marker lamps).
- 49 CFR 393.11 (commercial vehicle lighting), Transport Canada TP14116E and TP14117E (truck, bus and trailer lighting), NTEA FMVSS 108 lighting guide.
- UN Regulation No. 48 (EUR-Lex 2021/1718 and earlier), UN R38 (rear fog lamps), UN R148 (light-signalling devices), WP.29/GRE documents on emergency stop signals and illuminated logos (UN Digital Library, globalautoregs.com); Australian Design Rules 13/00 and 102/00.
- SAE J3134 (ADS marker lamp), Stanford CIS and Mercedes-Benz on DRIVE PILOT marker lamps, California Highway Patrol bulletins (ADS lamps, warning lamps).
- State emergency lighting rules: Washington WAC 204-21-130, Iowa Code 321.424, California Vehicle Code (CHP 884); NIJ law enforcement vehicle lighting overview.
- Kia and Honda owner's manuals (emergency stop signal).
- Interior lighting overviews: Ansys, Keysight, Lighting Research Center (RPI), S&P Global Mobility.
- Vehicle widths: each vehicle's `vehicleParameters_<ID>.mat` (`DistancesWidth`), read 2026-11-26.
