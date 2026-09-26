# Flight state across restarts

**Available now.**

## What it does

Restarting xatc used to put a flight back to "parked" -- the clearance, squawk, phase,
taxi route, pending readback, everything the engine was tracking lived only in memory.
That's a real problem the moment you need to restart mid-flight to pick up a code fix or
a settings change without losing the flight. Now `xatc.atc.flight_state.FlightStateStore`
saves the engine's flight state to `flight_state.pkl`, right next to `settings.json`,
after every pilot call and whenever the engine says something or changes phase -- and
puts it back into the freshly built engine on the first tick after a restart.

## When it restores, and when it doesn't

A saved flight is only restored when all of these hold:

- **Same flight** -- the callsign, departure and destination all match exactly what was
  saved.
- **Recent enough** -- saved within the last 6 hours.
- **Hasn't moved far** -- the aircraft is still within 3 nm of where it was when the
  state was saved.

Anything else -- a genuinely new flight, a reposition, a save file too old to trust, or
one an updated version of xatc can no longer make sense of -- starts fresh instead of
guessing. Each field of the saved state is restored on its own, so a single field an
updated engine renamed or can't unpickle just keeps its freshly-built value rather than
failing the whole restore.

World data -- the airport, taxi graph, procedures, and controller positions -- and
callbacks (the readback judge, the conversational-ATC controller, conformance listeners)
are never part of the saved state; the freshly built engine's own copies of those are
always used, so a restart still picks up a code fix to any of them even while resuming
the same flight. The [radio panel's transcript](radio-panel.md) is saved and restored
alongside the flight state itself (the most recent 500 entries).

## Starting over on purpose

`xatc run --fresh-flight` ignores whatever's saved and starts from the ramp, even if a
matching flight's state is sitting right there. The **Reset flight** button on the [radio
panel](radio-panel.md) does the same thing without a restart: it drops the running
engine (built fresh on the next tick, wherever the aircraft is now) and clears the saved
file, so a subsequent restart doesn't bring the reset flight back either.

## Configuration

None -- this is always on for a `--live` run. `flight_state.pkl` lives next to
`settings.json` in your OS's standard config directory (see [Settings](../settings.md)
for the exact per-OS paths).

## Limitations

- Text-mode/replay development sessions don't use this -- it's a live-flight mechanism.
- A restore is all-or-nothing per field, not a merge of individual sub-values within one
  field -- an incompatible field is dropped and rebuilt fresh in its entirety.
