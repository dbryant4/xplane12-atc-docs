# Traffic advisories

**Live now.** `xatc run --live` reads X-Plane's AI and multiplayer aircraft straight from
the TCAS target datarefs (ADR 0010) and feeds them into the engine, about once a second,
on their own connection alongside the aircraft-state one. That drives traffic advisories
and [wake turbulence cautions](#wake-turbulence-cautions-f11-f12) below, plus
[sequencing](../roadmap.md#m7-traffic-awareness) (M7-3) behind other traffic on approach
or in the pattern. A **"Traffic N"** chip in the [radio panel](radio-panel.md)'s header
confirms the feed is actually seeing something -- see [The live feed](#the-live-feed)
below.

**Not yet confirmed against real AI traffic on a running X-Plane 12.4.3.** The dataref
names, decoding and fallbacks below are all built and tested against synthetic data; `xatc
smoke --live --tcas-seconds 5` (see below) is how to check what a real X-Plane build
actually reports before relying on this in the air.

## What it does

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

The same live traffic feed (see below) also drives wake turbulence
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

## The live feed

`SimBridge.traffic()` reads the shared TCAS target arrays (`sim/cockpit2/tcas/targets/*`)
that AI traffic, multiplayer plugins and X-Plane's own TCAS all write to -- not the
legacy `sim/multiplayer/position/planeN_*` datarefs, which cap out at 19 aircraft.
Parked aircraft on the ground are never fed into advisories, sequencing or wake
tracking -- all three already ignore a target once its `on_ground` flag (or, on an
X-Plane build missing that dataref, a below-50-kt groundspeed fallback) is set.

- **If a required TCAS dataref is missing** on this X-Plane build, the feed retries
  every 60 seconds and logs why -- it never takes the rest of the flight down with it. A
  dropped connection (X-Plane not up yet, or a brief disconnect) retries much sooner,
  doubling from 1 second up to 10.
- **`xatc smoke --live --tcas-seconds 5`** samples the raw arrays for a few seconds and
  prints exactly what X-Plane reports for each target -- lat/lon/elevation/heading/Mode
  S/type, plus (marked "unverified," since they haven't been confirmed live yet)
  velocity, weight-on-wheels and flight id. Run this against a real flight with AI
  traffic before trusting the feed.
- **The panel's "Traffic N" chip** is the day-to-day way to confirm the same thing
  without a terminal: it shows the current target count, with "N nearby, M airborne" in
  its tooltip. Hidden -- not shown as "Traffic 0" -- whenever there's nothing to report,
  which covers three different situations the panel can't tell apart (no feed at all, a
  stale one, or a genuine clear sky) equally honestly.
- **`xatc record`** now records traffic alongside aircraft state, and `--replay` plays it
  back. An older recording (with no traffic in it) still replays unchanged on this
  version -- it just has no traffic -- but a recording made now, with traffic in it,
  can't be replayed by an older xatc. Traffic itself isn't restored across a restart: the
  saved [flight state](flight-state.md) doesn't carry it.
