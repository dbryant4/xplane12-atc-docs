# Flight state across restarts

**Available now.**

## What it does

Restarting xatc used to put a flight back to "parked" -- the clearance, squawk, phase,
taxi route, pending readback, everything the engine was tracking lived only in memory.
That's a real problem the moment you need to restart mid-flight to pick up a code fix or
a settings change without losing the flight. Now `xatc.atc.flight_state.FlightStateStore`
saves the engine's flight state to `flight_state.pkl`, right next to `settings.json`,
immediately after every pilot call and whenever the engine says something or changes
phase, and otherwise about every 10 seconds -- and puts it back into the freshly built
engine on the first tick after a restart. This only runs on a `--live` run with a flight
plan (a resolved callsign); it never applies in text-mode/replay development sessions.

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

**The ATIS plays again after a restart, too.** The [voice session](voice.md) only
remembers a broadcast from an actual `speak()` call, which the engine makes just once,
when the information letter changes -- not something a restore alone would trigger. The
restored engine re-broadcasts its current letter to the freshly built voice session on
that first tick, so you're not left with a resumed flight and no ATIS playing at all
until the letter happens to change again.

## Starting over on purpose

`xatc run --fresh-flight` ignores whatever's saved and starts over, even if a matching
flight's state is sitting right there. The **Reset flight** button on the [radio
panel](radio-panel.md) does the same thing without a restart: it drops the running
engine and starts over parked, where the aircraft actually is (built fresh on the next
tick), and clears the saved file, so a subsequent restart doesn't bring the reset flight
back either.

## Configuration

None -- this is always on for a `--live` run. `flight_state.pkl` lives next to
`settings.json` in your OS's standard config directory (see [Settings](../settings.md)
for the exact per-OS paths).

## Limitations

- A restore is all-or-nothing per field, not a merge of individual sub-values within one
  field -- an incompatible field is dropped and rebuilt fresh in its entirety.
