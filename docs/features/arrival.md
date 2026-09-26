# Arrival (descent, approach, landing)

**Available now: gate-to-gate, including a go-around.** Descent, the approach handoff
and clearance, the landing clearance, taxi-in to a stand, parking, and a missed
approach if you go around all work end to end.

Arrivals were built in four slices, the same pattern the departure phase used (Tower,
then Departure, then Center): descent and the STAR clearance, the approach handoff and
clearance, the landing clearance and taxi-in, then go-around/missed-approach handling
and parking. All four are done -- M4 is complete.

## Descent (M4-1)

A little before the aircraft's actual top of descent, Center starts it down:

```
descend via the Kratr Three arrival, Buwzo transition,
Portland information Bravo is current, Portland altimeter three zero zero two
```

-- or, when there's no STAR that fits (no CIFP data for the destination, or nothing in
it matches the filed route):

```
descend and maintain one one thousand,
Portland information Bravo is current, Portland altimeter three zero zero two
```

This is a one-shot event -- it fires once, moves the flight phase to `DESCENT`, and
(without a STAR) the assigned altitude is readback-checked just like any other altitude
instruction. With a STAR, the assigned altitude becomes that STAR's own lowest charted
constraint, which is where "descend via" is actually supposed to end up.

### How the descent, runway, and STAR are picked

`xatc.atc.arrival_planner.should_issue_descent` decides *when*: a little before the
aircraft's own top-of-descent point for its current altitude and the destination's
field elevation, so the call comes with enough lead time to actually be useful. Once
it's time, `xatc.atc.arrival_planner.plan_arrival` decides *what*:

- **Landing runway**: the destination's own flow rules (the same wind-based selection
  [departure runways](runway-selection.md) already use), evaluated against the
  destination's own weather -- which the engine tracks separately from the aircraft's
  weather the moment a destination is known, falling back to the aircraft's own weather
  until a real reading for the destination arrives.
- **STAR and transition**: chosen the same way [SID selection](sid-departure-procedures.md)
  picks a departure procedure -- matched against the filed route, or `None` (no STAR --
  a straight-in-style descent instead) if the destination has no CIFP data or nothing in
  it fits.
- **Approach type**: ILS, RNAV, LOC or visual, from CIFP data and the destination's
  weather ceiling/visibility -- this is what the approach clearance below actually
  speaks.

Without CIFP data for the destination at all, the plan still works: no STAR, and a
generic visual approach placed at the airport's own reference point from its apt.dat.

## Approach handoff and clearance (M4-2)

Center hands off to the destination's Approach position -- either around 40 nm from the
field, or on reaching the STAR's own terminal fix if that comes first, whichever the
aircraft reaches first, and never within the first 20 seconds of the descent call (so a
close-in arrival that starts descending already inside 40 nm doesn't get both calls back
to back):

```
contact Portland Approach one one eight point one
```

Checking in on Approach gets the current altimeter and either an expected-approach
callout (still on the STAR) or vectors, depending on whether a STAR was assigned:

```
Portland Approach, Portland altimeter three zero zero two, descend and maintain two
thousand, expect ILS runway two eight right approach
```

Once established -- on the STAR's own final course, or, when being vectored, within 4 nm
of a vectoring point 15 nm out on the extended centerline -- Approach issues the actual
approach clearance (FAA 7110.65 4-8-1):

```
cleared ILS runway two eight right approach
```

or, with a vector still needed to intercept:

```
turn right heading two five zero, maintain two thousand until established on the
localizer, cleared ILS runway two eight right approach
```

## Approach vectoring (F16)

When there's no STAR -- or a go-around resequences the aircraft with no STAR either --
Approach doesn't just give one heading toward a point on the final and leave it there.
It builds an actual pattern (`xatc.atc.vectoring`, tied into the engine's `_maybe_vector`
and `_maybe_clear_approach`) and flies it leg by leg, the way a real controller would.

### Choosing the entry

At check-in, from where the aircraft is relative to the final approach course:

- **Straight-in**: already within 30° of the final, seen from where the final vector
  would join it, and at least 2 nm beyond that point. One leg: fly straight to it.
- **Base entry**: off to one side, beyond the base turn. One leg: the base turn point.
- **Downwind**: anywhere else -- abeam or ahead of the runway, or past it. Two legs:
  join the downwind, then the base turn point at its end.

Whichever pattern is picked, it's flown on the aircraft's own side of the final -- it's
never turned across the extended centerline to build a pattern on the other side. How
far out the downwind, the base turn and the final-vector intercept point are all scale
with the aircraft's own performance class: a jet gets a downwind 5 nm abeam the
centerline with an intercept point at least 8 nm out; a turboprop, 4 and 7; a piston, 3
and 5 -- so a light single isn't sent 13 miles out for its base the way an airliner is.

### Flying the pattern

One heading change at a time, never more than one every 30 seconds, each with the
altitude step that goes with it -- stepping down 1,000 ft per leg so the aircraft
reaches the approach altitude by the base turn. If the track drifts more than 10° off
what the assigned heading should be making good, sustained for 30 seconds (allowing for
the wind doing the drifting), Approach corrects it with another heading -- "turn left
heading two four zero" if it actually turned, "fly heading two four zero" if it never
did.

If the aircraft ends up on the wrong side of the final -- a missed turn, a strong
crosswind -- Approach doesn't try to turn it back across; it builds a new pattern from
wherever it actually is now.

### The final vector

Once a 30° intercept from the aircraft's current position would join the final at or
outside the intercept point (7110.65 5-9-1: at least 2 nm outside the approach gate, so
at least 3 nm outside the FAF overall), the final vector comes with its distance from
the FAF, folded into the approach clearance from above:

```
five miles from Toloc, turn left heading three one zero, maintain two thousand until
established on the localizer, cleared ILS runway two eight right approach
```

### A heading you ask for

[Conversational ATC](intent-parsing.md#conversational-atc-f17) can grant a heading you ask
for directly ("can we get a left turn for the downwind?") -- Approach flies that heading
as given, and it isn't overridden by the next scheduled turn. Vectoring picks back up on
its own about a minute later, planning a fresh pattern from wherever that heading
actually took the aircraft.

### On the radio panel

While vectoring, the [route map](radio-panel.md) draws the pattern instead of the filed
route: the extended centerline, the FAF, and every point Approach has planned (the
downwind join, the base turn, the turn to final) with the leg you're on and the next one
highlighted, and a caption like "vectors: right downwind, next: base turn, 9.8 nm".

## Landing clearance and taxi-in (M4-3)

Approach hands off to Tower at the approach's own charted final approach fix (from CIFP
data) when there is one, or 5 nm out otherwise:

```
contact Portland Tower one one eight point seven
```

Checking in on Tower gets the landing clearance (FAA 7110.65 3-10-5), with the current
wind when it's known:

```
wind two eight zero at one zero, runway two eight right, cleared to land
```

Once the aircraft has slowed to taxi speed and is clear of the runway, Tower hands off
to Ground and the flight phase becomes `TAXI_IN`:

```
contact Portland Ground one two one point niner
```

Ground then taxis the aircraft to a stand -- a spot the pilot names (resolved the same
way [taxi routing](taxi-routing.md)'s destination mode already works, via the fuzzy ramp
resolver), or the nearest gate if nothing was said or it didn't match anything:

```
taxi to Charlie one zero via Tango, Kilo, cross runway three
```

The landing runway itself is exempt from the taxi route's usual runway-crossing
avoidance, so any *other* runway the route crosses on the way to the stand still gets its
own "cross runway X" clause -- and, like a taxi-*out* crossing, has to be read back
correctly (a new `taxi_in` [readback kind](readback-checking.md)) before the flight is
considered clear to keep going.

Calling the destination's Ground always gets taxi-to-parking, whatever flight phase the
landing actually left behind -- a live KPDX flight missed its Tower check-in, which left
the phase at `APPROACH` even after touchdown, and calling Ground from there got
Portland's own *departure* taxi instead of a taxi to a stand. Now, being down on the
ground and calling the destination's own Ground position is what matters, not which of
`APPROACH`/`LANDING`/`TAXI_IN` the phase still happens to say.

## Go-around and missed approach (M4-4)

Say "going around" (or "missed approach") in `APPROACH` or `LANDING` and ATC actually
sends you around, instead of just noticing and asking what your intentions are:

```
roger, fly the published missed approach, contact Portland Approach one one eight
point one
```

-- using the approach's own charted missed-approach procedure and altitude when CIFP
data has one, or a generic "fly runway heading, climb and maintain \<altitude\>" when it
doesn't. Calling it in while already back on Approach's own frequency (before Tower ever
took the handoff) skips the "contact" clause and re-sequences you immediately instead:

```
roger, fly heading two five zero, climb and maintain three thousand, vectors ILS
runway two eight right approach
```

Either way, the flight phase drops back to `APPROACH`, the landing clearance is
cleared, and the whole approach-handoff-and-clearance sequence from above runs again
for another try -- you get vectored around, cleared for the approach again, handed to
Tower at the FAF again, and cleared to land again, exactly the same way as the first
attempt. Calling "going around" outside `APPROACH`/`LANDING` just gets "say again" --
there's nothing to go around from yet.

## Parking

Once the aircraft actually stops at its cleared stand (or the nearest gate) with the
parking brake set or the engines shut down, the flight phase becomes `PARKED` again --
the same phase the flight started in. **Nothing is transmitted.** Real Ground doesn't
say anything when you park; you're just done.

## Landing conformance

Two more conformance rules, specific to landing (`xatc.atc.conformance_landing`),
alongside the existing [ground and airborne rules](conformance-monitor.md):

- **Landing without clearance**: touching down while arriving without a landing
  clearance on file goes straight to "possible pilot deviation" -- no gentler step first,
  the same way a takeoff without clearance does.
- **An unreported go-around**: coming down to within 1,000 ft AGL and then climbing back
  away from the runway at a real climb rate, sustained, without ever having landed.

Both are spoken from the destination's Tower -- except the go-around rule doesn't
actually say "say intentions" anymore now that a real go-around exists: firing it now
directly triggers the missed-approach handling above instead, so an unreported go-around
gets the exact same "fly the published missed approach" treatment as one you called in,
rather than a callout asking what you're doing.

## Limitations

- No direct-to clearances or crossing restrictions anywhere in the arrival phase.
- Center's frequency *within* whichever ARTCC facility is currently talking to you --
  and the Approach/Tower callsigns -- still come from the same deterministic placeholder
  rule (a bearing wedge into `atc.dat`'s frequency list) [Departure &
  Center](departure-center.md) documents; not real TRACON/Center sector geometry. *Which*
  ARTCC facility you're on, though, is real -- see [Departure &
  Center](departure-center.md#center-to-center-handoffs) for Center-to-Center handoffs
  crossing an actual ARTCC boundary.
- **Approach vectoring doesn't model minimum vectoring altitudes.** Altitude steps down
  toward the approach altitude by the base leg; it doesn't yet check that against real
  MVA data for the airspace it's actually flying through.
- **A rare small overshoot of the final on a base entry, in strong crosswinds**, before
  the next correction catches it -- the pattern tolerates a little drift across the
  final before deciding it actually needs a new one.

## Verification

Unit tests (`tests/atc/test_engine_arrival.py`, 59 tests) cover the descent, approach
handoff and clearance, landing/taxi-in, go-around/missed-approach, and parking logic
individually, against real KSEA/KPDX CIFP and weather data. `tests/atc/
test_conformance_landing.py` covers both landing-conformance rules. A full scripted
KSEA-to-KPDX arrival (`tests/scenarios/test_m4_arrival.py`, 8 tests) flies the real
engine and the real intent parser (no stubs) end to end -- descent, Approach check-in
and clearance, Tower check-in and landing, rollout, taxi to a named gate, and parking --
and asserts the *exact, complete* transmission sequence: any extra or missing call,
including a conformance callout that shouldn't have fired, fails the test.

`tests/atc/test_vectoring.py` (30 tests) covers the vectoring planner on KPDX's runway
28R (ILS, FAF Toloc 5.9 nm out): all three entries, the leg-by-leg headings and altitude
steps, drift correction, a replan after crossing the final, the final vector's distance
and 30° intercept, and a missed-approach resequence -- a simulated pilot flies whatever
heading and altitude Approach assigns and reads every instruction back, from check-in to
the approach clearance.
