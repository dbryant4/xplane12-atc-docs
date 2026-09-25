# IFR clearance (CRAFT)

**Available now.**

## What it does

When you request an IFR clearance on Clearance Delivery, the engine builds a full CRAFT
clearance -- **C**learance limit, **R**oute, **A**ltitude, **F**requency, **T**ransponder
-- and reads it back in FAA phraseology.

Real example (from the project's own MVP acceptance test), for *"Seattle Clearance,
November five four seven Golf Alpha, IFR to Portland with information Alpha"*:

```
November five four seven Golf Alpha, cleared to Portland International airport,
via radar vectors, then as filed, climb and maintain five thousand,
expect one zero thousand ten minutes after departure,
departure frequency one two five point four, squawk four five two one
```

(or, when a SID is on file: *"...via the CASCO2 departure, then as filed..."* instead of
*"via radar vectors."*)

## How it decides

- Requires current weather -- if none has arrived yet, you get *"unable, stand by"*
  rather than a guessed clearance.
- The active departure runway comes from [runway selection](runway-selection.md).
- **Initial altitude is always 5,000 ft** (or your filed cruise altitude if it's lower)
  -- there's no climb-gradient or airspace-based initial-altitude logic yet.
- **The SID is whatever's on your filed flight plan, never assigned by ATC** -- there's
  no CIFP SID parser in the project yet, so the engine can't pick one itself. No SID
  filed means the clearance reads "via radar vectors" instead.
- The filed route string itself (e.g. "SEA J1 BTG") is deliberately **never spoken** --
  it would just be spelled out letter by letter by the TTS, so the renderer always says
  "then as filed" instead.
- **Squawk code**: derived deterministically from the callsign (not a real
  conflict-free registry -- this is a single-aircraft engine), remapped away from
  reserved codes like 7500/7600/7700 if it happens to land on one.
- `expect_minutes` (how long until you should expect your filed cruise altitude) is a
  constant 10 minutes, not computed from anything.

## Readback

Any readback is currently accepted as correct -- there's no field-by-field comparison
against what was actually issued. See [Conformance monitor](conformance-monitor.md) for
what a real correction check would look like once it exists.

## Configuration

The flight plan (callsign, aircraft type, destination, route, cruise altitude) comes
from `xatc run`'s CLI flags today (`--callsign`, `--aircraft-type`, `--dest`, `--route`,
`--cruise`) -- there's no SimBrief import yet.

## Limitations

- No CIFP SID parser -- ATC never assigns a SID, only echoes whatever you filed.
- `expect_minutes` is a hardcoded constant.
- No readback correction.
- The ATIS information letter you state back is tracked but not enforced -- any letter
  you say is accepted.
