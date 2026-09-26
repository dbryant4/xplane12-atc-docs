# Traffic advisories

**Built and tested end to end -- not live yet.** Both traffic advisories and [wake
turbulence cautions](#wake-turbulence-cautions-f11-f12) below are fully wired into the
engine, but nothing feeds either of them real X-Plane traffic today:
`xatc.sim.bridge.SimBridge` (the interface `xatc run --live` actually uses) has no
`traffic()` method yet, and nothing calls the engine's traffic-ingestion hook outside of
tests. See [ADR 0010](../roadmap.md) in the repository -- it's still "accepted, pending
live confirmation of the TCAS datarefs."

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

## Wake turbulence cautions (F11, F12)

The same traffic feed (once it's live -- see below) also drives wake turbulence
cautions (FAA 7110.65 2-1-20): a takeoff or landing clearance on a runway a Heavy or a
Super departed from or landed on recently ends with **"caution wake turbulence"**, and
so does a [sequencing call](../roadmap.md#m7-traffic-awareness) behind one (M7-3).

"Recently" is category-specific: **2 minutes behind a Heavy, 3 minutes behind a
Super** (`xatc.atc.wake.WakeTracker`, tracking each Heavy/Super target's departures and
landings by which runway end its heading matches). Two runways count as the same one for
this if their centerlines are **less than 2,500 ft apart and run the same direction** --
close, staggered parallels like KSEA's 16L/16C/16R -- so a landing on 16C still cautions
the next departure off 16L. Runways that only *cross* the one in question (a different
course entirely, not a close parallel) are never folded in, however near their
thresholds might be on the airport diagram.

## Today, this only runs against test data

Until `SimBridge.traffic()` (the live X-Plane side) and the `xatc run --live` wiring that
feeds its output into `on_traffic()` both land, none of the above -- traffic advisories
or wake turbulence cautions -- runs against a real flight. Both only exercise the full
pipeline in the test suite today, against synthetic straight-line targets.
