# Arrival (descent, approach, landing)

**In progress -- M4-1 done (descent and STAR clearance); approach and landing not yet
built.**

Arrivals are being built in three slices, the same pattern the departure phase used
(Tower, then Departure, then Center): descent and the STAR clearance first, then the
approach handoff and clearance, then the landing clearance and taxi-in. Only the first
slice exists today.

## M4-1: Center starts the descent

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

Either way, this is a one-shot event -- it fires once, moves the flight phase to
`DESCENT`, and (without a STAR) the assigned altitude is readback-checked just like any
other altitude instruction. With a STAR, the assigned altitude becomes that STAR's own
lowest charted constraint, which is where "descend via" is actually supposed to end up.

## How the descent, runway, and STAR are picked

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
- **Approach type**: from CIFP data and the destination's own weather ceiling/visibility
  (not used by M4-1 yet -- see Limitations below).

Without CIFP data for the destination at all, the plan still works: no STAR, and a
generic visual approach placed at the airport's own reference point from its apt.dat.

## Limitations

- **Only M4-1 exists.** Nothing hands the aircraft off from Center to Approach yet, and
  there's no approach or landing clearance -- the flight simply stays in `DESCENT` on
  Center's frequency once this fires. Approach handoff/clearance (M4-2) and the landing
  clearance/taxi-in (M4-3) are next -- see the [Roadmap](../roadmap.md).
- The approach type `plan_arrival` already picks (ILS/RNAV/LOC/visual, from ceiling and
  visibility) isn't spoken or used for anything yet -- that's M4-2's job.
- No airborne conformance monitoring past `ENROUTE`/`DESCENT` for the approach and
  landing phases those slices will add.

## Verification

Unit tests cover `should_issue_descent`'s timing against synthetic top-of-descent
scenarios, `plan_arrival`'s STAR/runway/approach-type selection against real KSEA/KPDX
CIFP and weather data (including the no-CIFP visual-approach fallback), and the engine's
own one-shot descent-issuance behavior, the STAR-vs-no-STAR wording, and the readback
gating on a no-STAR altitude assignment.
