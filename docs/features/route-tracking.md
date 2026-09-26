# Route tracking (en-route next fix)

**Available now.**

## What it does

The owner, flying KPDX → KSEA live: *"the ENROUTE phase should have a substate that is
the next navigational point. That's how ATC really works."* Once airborne and past the
initial climb, the engine keeps a live route -- the filed route's fixes, plus the
assigned [STAR](arrival.md)'s own transition, common route and runway-transition fixes
once a descent plan exists -- and tracks which fix on it the aircraft is heading for
right now.

This is what drives:

- The **[Route map card](radio-panel.md)** on the radio panel, showing the filed fixes
  with the one you're tracking highlighted and anything already behind you dimmed.
- **[Direct-to](enroute-requests.md#direct-to)** validation and "that's behind you"
  denials.
- **[Departure's](departure-center.md#direct-to-or-resume-own-navigation-at-radar-contact)**
  choice of which fix to clear you direct to at radar contact.
- Automatically **turning a radar-vectored aircraft back onto its route**.
- The **off-course check** below.

## How a fix gets marked passed

A fix counts as passed once the aircraft comes within 2 nm of it, or once it's *abeam*
the fix -- past it along the leg from the previous fix, even if the aircraft never
actually flew directly over it (a fix well off to one side of a wide turn shouldn't stay
"next" forever). Several fixes can pass in a single check if the aircraft skipped past
more than one -- flying a shortcut, or a vector that rejoined the route well ahead of
where it left it.

A [direct-to](enroute-requests.md#direct-to) makes the requested fix next and drops
everything before it from consideration; the current leg then starts from wherever the
aircraft was at the moment the direct-to was issued, not from the previously-tracked leg
start -- otherwise a direct-to given well off to one side of the old leg would read as
instantly far off course.

## Turning a vector back onto the route

When [Tower assigns a takeoff heading for radar vectors](tower-clearance.md#takeoff-heading-on-radar-vectors),
or Approach/Center otherwise puts the aircraft on a heading, the route keeps tracking in
the background but the off-course check (below) stands down while a heading is actually
assigned. After the aircraft has been on that heading for 2 minutes -- and only while
still navigating toward the route via [Departure or
Center](departure-center.md) (not while Approach is actively vectoring for the approach
itself, and not with a handoff or a readback still pending) -- the controller currently
working the aircraft clears it direct to the next fix on its own:

```
"...proceed direct Battle Ground"
```

This is read back like any other direct-to.

## Off-course monitoring

`xatc.atc.route_track.OffCourseMonitor` checks the aircraft's distance off the current
leg (the previous fix, or wherever a direct-to was issued from, to the next fix) --
but only while it's actually supposed to be navigating that leg itself: never while on
an assigned heading (a vector), and never right after an approved
[deviation](enroute-requests.md#weather-deviation) that hasn't yet been resumed. The
tolerance scales with [conformance strictness](conformance-monitor.md):

| Strictness | Off-course tolerance | Sustained before it fires |
|---|---|---|
| Relaxed | 5 nm | 60 s |
| **Normal** (default) | 3 nm | 30 s |
| Checkride | 2 nm | 20 s |

Once it fires: *"you appear to be off course, proceed direct Battle Ground"*, escalating
straight to "possible pilot deviation" if it isn't corrected.

## Configuration

None -- route tracking follows directly from the filed flight plan and, once assigned,
the destination's STAR.

## Limitations

- A route fix with no matching position in the loaded nav data is skipped with a warning
  rather than blocking the whole route.
- The map card and next-fix tracking only run once airborne past the initial departure
  climb (`DEPARTURE`, `ENROUTE`, `DESCENT`) -- there's no route view while still on the
  ground or in the initial takeoff phase.
