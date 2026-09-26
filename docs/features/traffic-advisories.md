# Traffic advisories

**Built and tested end to end -- not live yet.** The advisory logic is fully wired into
the engine, but nothing feeds it real X-Plane traffic today: `xatc.sim.bridge.SimBridge`
(the interface `xatc run --live` actually uses) has no `traffic()` method yet, and
nothing calls the engine's traffic-ingestion hook outside of tests. See [ADR
0010](../roadmap.md) in the repository -- it's still "accepted, pending live
confirmation of the TCAS datarefs."

## What it does, once the feed lands

The engine already accepts a live snapshot of other aircraft
(`AtcEngine.on_traffic(targets)`, about 1 Hz per ADR 0010) and, every tick, calls out any
target that's:

- airborne,
- within 1,000 ft of your own ATC altitude,
- within 5 nm, and
- **converging** -- actually closing the range, not just nearby or flying away.

The call: *"traffic, twelve o'clock, five miles, opposite direction, Boeing seven thirty
seven, altitude indicates same altitude."* Direction is "same direction," "opposite
direction," or "crossing left to right"/"crossing right to left" from the two aircraft's
tracks; the aircraft type is spoken when known; altitude is "same altitude" within 100
ft, else "indicates &lt;n&gt; feet above/below you."

A repeated advisory backs off (60s, then 30s after the pilot's said "looking," capped at
two repeats) and stops once you report the traffic in sight -- a plain "roger" from
there.

## Who calls it

Whoever has the aircraft airborne right now -- Tower in the pattern, Departure, Center or
Approach otherwise -- but never Ground, and never for a VFR flight with no [flight
following](vfr-flight-following.md) active (there's no one watching an unassisted VFR
flight to call traffic against). Suppressed entirely on the ground, during an
[emergency](emergencies.md), and for a second right around another handoff or readback,
so calls don't collide.

## Today, this only runs against test data

Until `SimBridge.traffic()` (the live X-Plane side) and the `xatc run --live` wiring that
feeds its output into `on_traffic()` both land, this logic only exercises the full
pipeline in the test suite, against synthetic straight-line targets -- not in a real
flight.
