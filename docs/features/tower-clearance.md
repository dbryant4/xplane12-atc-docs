# Tower takeoff clearance

**Available now** (a direct takeoff clearance). **Line-up-and-wait: not wired up.**

## What it does

Once you're holding short and call ready for departure, Tower clears you for takeoff:

```
"...runway one six left, cleared for takeoff"
```

This also transitions the flight phase to takeoff, and sets up the [automatic handoff to
Departure](controller-positions.md#handoffs) once you're airborne above 1,000 ft AGL.

### Takeoff heading on radar vectors

When the [IFR clearance](ifr-clearance.md) has no SID (a radar-vectors departure), the
takeoff clearance itself carries a heading to fly:

```
"...fly heading two seven zero, runway two five left, cleared for takeoff"
```

The heading is the runway's own magnetic heading rounded to the nearest 10&deg; --
straight out, not a turn -- and Departure uses that same assigned heading to answer "do
you still want us on this heading" and to know when to clear you direct or say
"resume own navigation" (see [Departure & Center](departure-center.md)). A departure with
a SID doesn't get a heading in the takeoff clearance; the SID itself defines the initial
track.

## How it decides

- Only fires from `HOLD_SHORT`. Too early (not at the hold line yet) or asking again
  after you've already been cleared both get *"say again"* instead.
- The runway comes from your existing clearance if you have one, or a fresh [runway
  selection](runway-selection.md) otherwise.
- This is a **direct** clearance -- a deliberate scope choice for the takeoff clearance
  specifically, not a sign xatc has no sequencing at all: [Approach's landing
  clearance and the VFR pattern's runway queue](../roadmap.md#m7-traffic-awareness)
  (M7-3) do sequence behind other traffic, fed by the live [traffic
  feed](traffic-advisories.md); Tower's takeoff clearance still never does. A real
  Tower might instead say "line up and wait" behind other traffic on this runway;
  that's out of scope here.
- **Wake turbulence caution** does fold in here, the same way it does everywhere else a
  clearance is issued on a runway: "…runway one six left, cleared for takeoff, caution
  wake turbulence" when a Heavy or Super used that runway in the last 2-3 minutes (F11,
  F12) -- see [Traffic advisories](traffic-advisories.md#wake-turbulence-cautions-f11-f12).

## What exists but isn't used yet

The phraseology for "line up and wait" (7110.65 3-9-4: *"(callsign) runway (number),
line up and wait"*) is fully implemented and tested as a standalone renderer, and
`Clearance` has a `line_up_and_wait` field for it -- but the takeoff clearance never
calls it or sets that field for this reason (a separate, unrelated use of the same field
name marks a repositioned-onto-the-runway aircraft's state after F13's reposition
handling, not an actual spoken "line up and wait"). There's currently no situation that
triggers the real phraseology.

## Configuration

None.

## Limitations

- No sequencing on the takeoff clearance itself -- always direct, never line-up-and-wait
  (see above; this is unrelated to whether sequencing exists elsewhere).
- No wind read as part of the takeoff clearance in practice (the renderer supports
  attaching one, but the engine doesn't supply it today).
- No go-arounds and no landing clearance flow yet -- see [Roadmap](../roadmap.md).
