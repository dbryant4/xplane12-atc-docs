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
via the Summa Two departure, Pangl transition, then as filed,
climb and maintain five thousand,
expect one zero thousand ten minutes after departure,
departure frequency one two five point four, squawk four five two one
```

(or *"...via radar vectors, then as filed..."* when no SID fits -- see [SID & departure
procedures](sid-departure-procedures.md) for how one's actually chosen.)

## How it decides

- Requires current weather -- if none has arrived yet, you get *"unable, stand by"*
  rather than a guessed clearance.
- The active departure runway comes from [runway selection](runway-selection.md).
- **Initial altitude is always 5,000 ft** (or your filed cruise altitude if it's lower)
  -- there's no climb-gradient or airspace-based initial-altitude logic yet.
- **The SID is chosen from real CIFP procedure data** for airports that have it (KSEA
  and KPDX today) -- see [SID & departure procedures](sid-departure-procedures.md).
  Without CIFP data for the airport, or when nothing in it fits the flight plan, the
  clearance reads "via radar vectors" instead.
- The filed route string itself (e.g. "SEA J1 BTG") is deliberately **never spoken** --
  it would just be spelled out letter by letter by the TTS, so the renderer always says
  "then as filed" instead.
- **Squawk code**: derived deterministically from the callsign (not a real
  conflict-free registry -- this is a single-aircraft engine), remapped away from
  reserved codes like 7500/7600/7700 if it happens to land on one.
- `expect_minutes` (how long until you should expect your filed cruise altitude) is a
  constant 10 minutes, not computed from anything.

## Readback

Your readback is checked field by field against what was actually issued -- miss the
altitude or squawk and you get corrected, not silently waved through. See [Readback
checking](readback-checking.md) for exactly what's required, what's only a warning, and
how ASR quirks are tolerated.

## Configuration

The flight plan (callsign, aircraft type, departure, destination, route, cruise
altitude, SID) comes from `xatc run`'s CLI flags (`--callsign`, `--aircraft-type`,
`--departure`, `--dest`, `--route`, `--cruise`), or from `--simbrief-user` to import it
from a SimBrief OFP -- see [SimBrief import](simbrief-import.md). Explicit CLI flags
override the matching SimBrief field.

## Limitations

- `expect_minutes` is a hardcoded constant.
- The ATIS information letter you state back is tracked but not enforced -- any letter
  you say is accepted.
