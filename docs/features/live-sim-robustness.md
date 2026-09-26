# Live-sim robustness (pause, replay, repositioning)

**Available now.**

## What it does

A live X-Plane session doesn't just fly a flight plan start to finish -- it gets paused,
rewound to replay a landing, repositioned to a different spot, or restarted as a whole
new flight, all mid-session. `AtcEngine.on_tick` checks for each of these before doing
anything else, so none of them produce a bogus conformance callout, a stuck timer, or a
flight stuck believing it's still where it was.

## Pausing the sim

While `AircraftState.paused` is set, nothing advances: no conformance check runs, no
timer ticks. The time spent paused is subtracted from every timer's clock once
unpaused, rather than counting against it -- pausing for five minutes to answer the
phone doesn't hand you a stale taxi clearance or an off-course call the moment you
un-pause. A sim-time reload (time moving backwards) is treated the same way a pause
reset is: every timer starts fresh rather than computing a bogus negative duration.

## Replay

While X-Plane is playing back a replay (`sim/time/is_in_replay`), ATC does nothing at
all -- the last live state is kept exactly as it was, so the flight picks up from there
once the replay ends, and the replay's own time (which can run backwards, or jump) never
reaches any timer. Live traffic snapshots are ignored during a replay too, since
[traffic advisories](enroute-requests.md) should reflect real other aircraft, not
whatever the replay happens to show.

## Repositioning

A position or altitude change too large for the aircraft to have actually flown in the
elapsed sim time -- Location > Set Position, a teleport, a sudden reload -- is detected
as a **reposition**, not a real deviation. The engine doesn't fault the aircraft for the
jump itself: every conformance monitor resets, any pending readback or handoff is
dropped, and the flight phase is re-derived from wherever the aircraft actually is now
(the runway if it's lined up on one, the pattern if it's flying one nearby, `DEPARTURE`
or `ENROUTE` if it's airborne near or far from the departure airport, `PARKED`
otherwise) rather than staying stuck in whatever phase it was in before the jump.

## Starting on a runway

X-Plane's own "start on runway" option (or a fresh session that just happens to begin
lined up on one) is handled the same way as a reposition, even on the very first tick:
the aircraft is treated as already cleared to line up and wait on that runway, not as an
unauthorized runway incursion. An earlier version of this got that wrong for a *new*
flight specifically -- a just-reset engine starting fresh on a runway got "hold
position!" instead -- fixed so a reset flight's first tick is checked the same way a
first-ever session's is.

## A new flight

A different tail number or aircraft type, or a jump to the ground far from both the
departure and destination airports, is treated as a genuinely new flight rather than a
reposition: the engine resets itself completely (back to `PARKED` with a fresh
clearance), the same reset the [saved flight state](flight-state.md) is cleared for, so
an old flight's leftover clearance or squawk can't leak into a new one that happens to
share the same session.

## Reset flight

The radio panel's **Reset flight** button (see [Radio panel](radio-panel.md)) does the
same full reset on demand, without needing an actual new aircraft or a jump: drop the
engine, rebuild fresh on the next tick wherever the aircraft currently is, and clear the
[saved flight state](flight-state.md) so a subsequent restart doesn't bring the old
flight back.

## Configuration

None -- all of this runs automatically on every live `--live` session; there's nothing to
turn on or off.

## Limitations

- Anomaly detection only looks at up to a few seconds of sim time between ticks -- a
  longer gap (e.g. a dropped connection) is treated as missing data, not a jump, so a
  genuine jump that happens to coincide with a connection drop isn't specially detected.
