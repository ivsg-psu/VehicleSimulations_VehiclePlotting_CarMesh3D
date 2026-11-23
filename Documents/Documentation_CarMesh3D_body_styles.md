# Body styles for CarMesh3D templates (draft, 2026-11-20)

Each body style gets one **exemplar**: a finished, checked vehicle (a downloaded model, processed like the Prius and Transit Connect) that can be refit to any other vehicle of that style when no model of that vehicle is found.

Status: **have** = finished exemplar exists; **model** = model downloaded, not yet processed; **need** = to download.

## Core set (light vehicles)

| # | Body style | What sets it apart | Suggested exemplar (popular, US-common) | Status |
|---|---|---|---|---|
| 1 | Sedan (3-box) | separate trunk, 4 doors | Toyota Camry (2018–2024) or Honda Accord | need |
| 2 | Hatchback (2-box, 5-door) | short rear, near-vertical hatch | Honda Civic hatchback or VW Golf | need |
| 3 | Liftback / fastback | sloped rear hatch | 2013 Toyota Prius Four | **have** |
| 4 | Station wagon | long roof to the rear, car height | Subaru Outback (or VW Golf SportWagen, Volvo V60) | need |
| 5 | Coupe (2-door) | 2 doors, sloped roof | Ford Mustang or Honda Civic coupe | need |
| 6 | Convertible / roadster | open top, 2 seats | Mazda MX-5 Miata | need |
| 7 | Sports car (mid-engine) | very low, wide | 2022 Acura NSX Type S (license NC-SA: see note) | **model** |
| 8 | Crossover / compact SUV | car-based, taller | Toyota RAV4 or Honda CR-V | need |
| 9 | Full-size SUV (body-on-frame) | tall, boxy, long | Chevrolet Tahoe or Ford Expedition | need |
| 10 | Minivan | tall, sliding doors, short hood | Honda Odyssey, Chrysler Pacifica, or Toyota Sienna | need |
| 11 | Pickup, full-size crew cab | cab plus open bed | Ford F-150 SuperCrew | need |
| 12 | Compact cargo van | small van, no rear side windows | 2014 Ford Transit Connect XLT Cargo LWB | **have** |
| 13 | Full-size high-roof cargo van | tall van, long body | Ford Transit, Mercedes Sprinter, or Ram ProMaster | need |

## Optional (add if wanted)

| # | Body style | Suggested exemplar |
|---|---|---|
| 14 | Midsize 3-row SUV | Ford Explorer or Toyota Highlander (a crossover can stand in) |
| 15 | Midsize pickup | Toyota Tacoma (the full-size pickup can stand in) |
| 16 | Passenger van (12–15 seats) | Ford Transit passenger van (the cargo van with windows) |
| 17 | Microcar / city car | Smart Fortwo |
| 18 | Box truck / cutaway | Isuzu NPR or Ford E-350 cutaway |
| 19 | Step van (delivery) | Freightliner MT45 (UPS/FedEx style) |
| 20 | School bus (type C) | Blue Bird Vision or Thomas C2 |
| 21 | Transit bus (40 ft) | New Flyer Xcelsior or Gillig Low Floor |
| 22 | Semi tractor (and 53 ft trailer) | Freightliner Cascadia |

Items 18 to 22 are larger than CarMesh3D's current vehicles: their wheels, axles (some have more than two), and trailers would need checks in the fitting code first.

## What makes a good download

- **License:** CC0 or CC-BY (as the Transit Connect). Avoid NonCommercial (NC) and ShareAlike (SA) if the repository is shared publicly or used in funded work: the NSX's CC BY-NC-SA would carry its terms onto the finished mesh.
- **Size:** low or medium poly (under about 200k triangles) is easiest; dense models work but are slow to convert and simplify.
- **Parts:** wheels as separate objects, and glass as its own material, save most label fixes.
- **Formats:** OBJ, STL, FBX, glTF/GLB, or .blend (FBX/GLB/.blend need Blender).
- **Source tip:** Sketchfab's "Downloadable" filter with a license filter. The Transit Connect's author (tonielpro520) has many free CC-BY production vehicles, including a 2006 Toyota Camry.

## Where to put each download

`Data/YEAR_Make_Model_Trimline/model/source/` with the model's `LICENSE.txt` (license name, author, and link) in `Data/YEAR_Make_Model_Trimline/model/`, as for the existing vehicles. Claude then adds the vehicleParameters (published dimensions, with sources), the vehicle script, the checks, and the body-style entry.
