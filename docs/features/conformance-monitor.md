# Conformance monitor

**Available now: ground and airborne rules, both wired into the engine and speaking.**

Two monitors watch whether the aircraft is actually doing what it's been cleared to do,
and escalate a callout the way a real controller would when it isn't: one for ground
movement, one for everything from the takeoff roll onward. Both are pure (no I/O,
deterministic on `AircraftState.t`), and both are checked every tick from
`AtcEngine.on_tick`.

## Ground conformance

`xatc.atc.conformance.ConformanceMonitor` -- `src/xatc/atc/conformance.py`.

### The four rules

| Rule | Fires when | Escalation |
|---|---|---|
| **Taxiing without clearance** | Moving on the ground before `taxi_cleared` is set, sustained past a short threshold | Gentle → firm → "possible pilot deviation" |
| **Off the taxi route** | Cleared to taxi, but farther from the assigned route than tolerance allows, sustained | Gentle → firm → "possible pilot deviation" |
| **Runway incursion** | Inside a runway's protected zone without a clearance that allows it -- fires immediately, no sustain time | "Hold position!" straight to "possible pilot deviation" |
| **Takeoff without clearance** | On runway pavement, aligned with it, moving, without a takeoff clearance | "Stop immediately" straight to "possible pilot deviation" |

Every rule fires once when a violation is established, steps up exactly one severity
level for each interval the violation continues (never repeating a step), and resets
once the aircraft has been back in conformance for a short recovery window -- so a brief
dip doesn't restart the ladder. A stopped aircraft (under 1 kt) doesn't keep escalating
an off-route call, since it's holding position as told. The off-route rule is suppressed
inside a runway's protected zone and whenever the clearance covers a line-up-and-wait or
takeoff, so an incursion never doubles up with an off-route call for the same moment.

### Verification

30 unit tests cover each rule's sustain boundary, the exact escalation timing, the reset
window, strictness scaling, and runway-crossing edge cases. A real recorded KSEA taxi-out
flight, replayed with a matching clearance, produces **zero false-positive events at
every strictness level** -- and the same replay with no taxi clearance at all correctly
fires the taxi-without-clearance rule. That verification runs two ways: directly against
`ConformanceMonitor`, and end to end through the wired-up `AtcEngine`, which is what
actually ships.

## Airborne conformance

`xatc.atc.conformance_airborne.AirborneConformanceMonitor` --
`src/xatc/atc/conformance_airborne.py`. Runs alongside the ground monitor, checking
altitude, heading, speed and squawk against the current clearance once the aircraft is
off the ground.

### The four rules

| Rule | Fires when | Ladder |
|---|---|---|
| **Altitude deviation** | More than the tolerance off the assigned altitude once the aircraft has reached it (an overshoot counts -- passing through the target reaches it). Before that, only moving the wrong way from it, or missing a climb/descent allowance, fires. A normal climb or descent toward a new assignment never fires. | Gentle → firm → "possible pilot deviation" |
| **Heading deviation** | More than the tolerance off the assigned magnetic heading, with wraparound at 360. Held to the tolerance once turned onto it; before that, a standard-rate-turn allowance. | Gentle → firm → "possible pilot deviation" |
| **Speed deviation** | IAS above the tighter of 250 kt below 10,000 ft MSL (14 CFR 91.117(a)) and any assigned speed, plus tolerance -- see the heavy-jet exception below | Gentle → firm → "possible pilot deviation" |
| **Wrong squawk** | The transponder code doesn't match the assigned code, or the mode is below ALT, for longer than a dial-in grace period | Gentle → firm only -- no pilot-deviation step |

Rules run only in the airborne phases the engine currently reaches -- `TAKEOFF` once off
the ground, `DEPARTURE`, `ENROUTE` -- and never on the ground. A new assignment (a
different altitude, heading, speed limit, or squawk code) restarts that rule's ladder.
Callouts are spoken from whichever position owns the aircraft right now: Tower once
airborne, Departure, or the dynamically created Center position once a handoff has
actually happened.

### What altitude ATC judges you on

A real controller doesn't see the sim's true geometric altitude -- their radar shows
pressure altitude corrected by the local altimeter setting (Mode C), and non-standard
temperature can put that several hundred feet away from true MSL. `atc_altitude_ft`
(`xatc.atc.altitude`) computes the altitude the monitor actually uses, from a runtime
**altitude source** setting:

- **Mode C** (default): pressure altitude, corrected below 18,000 ft by the local
  altimeter setting; a raw flight level at or above it.
- **Indicated**: the pilot's own altimeter, wrong setting and all.
- **True altitude**: the sim's geometric MSL elevation (the original, pre-setting
  behavior).

If the sim doesn't report the needed dataref (an old recording, or a sim version that
doesn't expose it), this falls back to true MSL and logs once, not on every tick.

### Heavy-jet exception

14 CFR 91.117(d) lets an aircraft exceed 250 kt below 10,000 ft if its minimum safe
airspeed requires it. With the **heavy-speed exception** on (the default), a Heavy or
Super-category aircraft (`xatc.world.aircraft_types`, a curated ICAO-designator table
sourced from FAA JO 7360.1) skips *only* that 250 kt limit -- an assigned speed is still
enforced regardless of category.

### Configuration

Altitude source, conformance strictness (**relaxed** / **normal** / **checkride**, same
three levels as the ground monitor, scaling every threshold at once), and the heavy-speed
exception are all runtime settings: adjustable from the radio panel's options screen,
persisted, and overridable for a single run with `--altitude-source`, `--strictness` and
`--no-heavy-speed-exception`. A change applies from the next tick; switching altitude
source specifically restarts altitude tracking so the switch itself can't cause an
instant false bust.

### Verification

53 unit tests cover each rule's capture/before-capture behavior, wraparound, escalation
timing, a new assignment restarting the ladder, strictness scaling, altitude-source
correctness (including cases where Mode C catches a bust that true MSL would miss, and
vice versa), and the heavy-jet exception. A further 7 tests cover the altitude-source
helper directly. Unlike the ground monitor, there's no real recorded-flight replay check
yet for the airborne rules -- only unit tests against synthetic and replayed states.

## Limitations

- **No landing or rollout rules.** Nothing airborne is checked past `ENROUTE` yet --
  the engine has no approach/landing phase to monitor (see the [Roadmap](../roadmap.md)).
- **Heading after "resume own navigation" or a direct-to.** The engine never assigns a
  heading today, so there's nothing for the heading rule to clear in that case yet.

The two monitors' shared escalation logic (fire once, step up the ladder, reset after
conforming) has since been factored into one common module,
`xatc.atc.conformance_core`, that both `conformance.py` and `conformance_airborne.py`
build on -- the earlier duplication between them is resolved. Readback checking is a
related but separate mechanism from this monitor -- see [Readback
checking](readback-checking.md).
