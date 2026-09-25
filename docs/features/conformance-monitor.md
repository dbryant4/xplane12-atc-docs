# Conformance monitor

**In progress: ground rules built, not yet wired into the engine.**

## What exists today

`xatc.atc.conformance.ConformanceMonitor` is a real, tested, standalone module --
`src/xatc/atc/conformance.py` -- that watches for four ground-conformance violations and
escalates them the way a real controller would. It's pure (no I/O, deterministic on
`AircraftState.t`) and is not yet called from anywhere in the engine, so nothing it
detects reaches the pilot yet.

### The four rules

| Rule | Fires when | Escalation |
|---|---|---|
| **Taxiing without clearance** | Moving on the ground before `taxi_cleared` is set, sustained past a short threshold | Gentle → firm → "possible pilot deviation" |
| **Off the taxi route** | Cleared to taxi, but farther from the assigned route than tolerance allows, sustained | Gentle → firm → "possible pilot deviation" |
| **Runway incursion** | Inside a runway's protected zone without a clearance that allows it -- fires immediately, no sustain time | "Hold position!" straight to "possible pilot deviation" |
| **Takeoff without clearance** | On runway pavement, aligned with it, moving, without a takeoff clearance | "Stop immediately" straight to "possible pilot deviation" |

### The escalation ladder

Every rule follows the same pattern: it fires once when a violation is established,
steps up exactly one severity level for each interval the violation continues (never
repeating a step), and resets once the aircraft has been back in conformance for a
short recovery window -- so a brief dip doesn't restart the ladder. A stopped aircraft
(under 1 kt) doesn't keep escalating an off-route call, since it's holding position as
told. The off-route rule is suppressed inside a runway's protected zone and whenever the
clearance covers a line-up-and-wait or takeoff, so an incursion never doubles up with an
off-route call for the same moment.

### Strictness

Three levels -- **relaxed**, **normal** (default), **checkride** -- scale every
threshold at once: how much off-route tolerance you get, how long a violation has to
sustain before it fires, how fast the ladder escalates, and how quickly it resets.
Checkride is the tightest (e.g. a 3-knot taxi threshold and a 30 m route tolerance
versus relaxed's 8 kt / 75 m), matching a stricter examiner rather than a lenient one.

## What's genuinely well-verified already

39 tests cover each rule's sustain boundary, the exact escalation timing, the reset
window, strictness scaling, and runway-crossing edge cases. A real recorded KSEA taxi-out
flight, replayed with a matching clearance, produces **zero false-positive events at
every strictness level** -- and the same replay with no taxi clearance at all correctly
fires the taxi-without-clearance rule. That's a meaningfully strong signal for a
first cut: it isn't just unit-tested in isolation, it's been checked against a real
flight and shown not to cry wolf.

## Configuration

`ConformanceMonitor(airport, strictness="normal")` -- strictness is a constructor
argument today; there's no CLI flag or config file for it yet, and nothing currently
constructs a `ConformanceMonitor` outside its own tests.

## Limitations

- **Not wired into the engine at all.** `on_tick` doesn't call it, so none of this
  reaches a pilot yet -- see the [Roadmap](../roadmap.md).
- Ground rules only -- no airborne conformance (altitude, heading, speed, squawk) and no
  landing/go-around rules.
- No readback *correction* either (see the readback note on [IFR
  clearance](ifr-clearance.md)) -- that's a related but separate gap.
- Runway-crossing clearances are inferred from the taxi route rather than an explicit
  field on `Clearance`; a few open design questions (an explicit `cleared_to_cross`
  field, an IMC/ILS-hold flag, exactly how severity maps to spoken wording and
  priority) are still open as of this writing.
