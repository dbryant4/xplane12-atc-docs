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
- This is a **direct** clearance -- there's no sequencing. A real Tower might instead
  say "line up and wait" behind other traffic; that's out of scope for this
  single-aircraft engine.

## What exists but isn't used yet

The phraseology for "line up and wait" (7110.65 3-9-4: *"(callsign) runway (number),
line up and wait"*) is fully implemented and tested as a standalone renderer, and
`Clearance` has a `line_up_and_wait` field for it -- but the engine never calls it or
sets that field. Since this is a single-aircraft MVP with no traffic to sequence behind,
there's currently no situation that would trigger it.

## Configuration

None.

## Limitations

- No sequencing -- always a direct takeoff clearance, never line-up-and-wait, since
  there's no other traffic to hold you for.
- No wind read as part of the takeoff clearance in practice (the renderer supports
  attaching one, but the engine doesn't supply it today).
- No go-arounds and no landing clearance flow yet -- see [Roadmap](../roadmap.md).
