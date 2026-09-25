# Conformance monitor

**Available now: ground, airborne and landing rules, all wired into the engine and
speaking.**

Three monitors watch whether the aircraft is actually doing what it's been cleared to
do, and escalate a callout the way a real controller would when it isn't: one for
ground movement, one for everything from the takeoff roll through approach, and one for
the landing itself. All three are pure (no I/O, deterministic on `AircraftState.t`),
and all three are checked every tick from `AtcEngine.on_tick`.

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

Rules run in every airborne phase the engine reaches -- `TAKEOFF` once off the ground,
`DEPARTURE`, `ENROUTE`, `DESCENT`, `APPROACH` -- and never on the ground, and never once
in `LANDING` (see [landing conformance](#landing-conformance) below, which takes over at
that point). A new assignment (a different altitude, heading, speed limit, or squawk
code) restarts that rule's ladder. Callouts are spoken from whichever position owns the
aircraft right now: Tower, Departure, or the dynamically created Center/Approach
position once a handoff has actually happened.

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

## Landing conformance

`xatc.atc.conformance_landing.LandingConformanceMonitor` --
`src/xatc/atc/conformance_landing.py`. Two rules, specific to the moment of landing:

| Rule | Fires when | Ladder |
|---|---|---|
| **Landing without clearance** | Touching down while arriving, without a landing clearance on file | Straight to "possible pilot deviation" -- no gentler step first, the same treatment a takeoff without clearance gets |
| **Unreported go-around** | Descending to within 1,000 ft AGL, then climbing back away from the runway at a real, sustained climb rate, without ever having landed | Straight into the real missed-approach handling -- see below |

Both are spoken from the destination's Tower. The go-around rule's escalation ladder
still exists internally (a gentler "say intentions" step before "possible pilot
deviation"), but firing it no longer speaks that wording: it's intercepted and sent
straight into [go-around and missed-approach
handling](arrival.md#go-around-and-missed-approach-m4-4) instead, the same "fly the
published missed approach" (or a runway-heading climb) treatment a pilot calling
"going around" out loud gets -- an unreported go-around is caught and handled exactly
like a reported one, not just called out.

### Verification

9 unit tests cover both rules' trigger conditions and escalation.

## Spoken wording, corrected

A phraseology audit against FAA JO 7110.65 caught two real bugs in what these monitors
actually said, both now fixed: the airborne monitor's altitude/heading/speed/squawk
callouts were built from raw numbers instead of routed through phraseology (`"climb and
maintain 5000"` instead of *"climb and maintain five thousand"*), and the ground
monitor's off-route-suppression callout spoke a bare taxiway letter (`"on taxiway B"`
instead of *"on taxiway Bravo"*). Both are covered by a golden-string test suite
(`tests/phraseology/test_golden_phraseology.py`) that pins the exact expected wording
for one example of each transmission type, citing the FAA paragraph it follows.

A fourth, related event -- **no check-in after a handoff** -- isn't a rule on any of
these three monitors; the engine raises it itself (`xatc.atc.conformance_core.RadioRule
.NO_CHECKIN`) the same moment it re-transmits a handoff reminder. See [Controller
positions & frequencies](controller-positions.md#handoffs) for that mechanism -- it
feeds the [debrief](debrief.md) the same way a real conformance event does, without
being one.

## Limitations

- **Heading after "resume own navigation" or a direct-to.** The engine never assigns a
  heading today, so there's nothing for the heading rule to clear in that case yet.

The three monitors' shared escalation logic (fire once, step up the ladder, reset after
conforming) is factored into one common module, `xatc.atc.conformance_core`, that
`conformance.py`, `conformance_airborne.py` and `conformance_landing.py` all build on.
Readback checking is a related but separate mechanism from these monitors -- see
[Readback checking](readback-checking.md).
