# VFR pattern work

**Available now, at a towered airport.**

## What it does

A VFR flight whose destination is the same as its departure flies the pattern: takeoff,
closed traffic, one or more touch-and-goes, then a full stop. Set **VFR** on the
[Settings page](radio-panel.md#settings)'s Flight tab (see [ADR 0008](../roadmap.md) in
the repository) with departure and destination the same airport, and Ground taxis you
out with no IFR clearance involved at all -- see [Pushback](pushback.md) for how the
IFR-clearance-first rule doesn't apply here.

## Closed traffic

Tower's takeoff clearance includes which way to turn: *"runway two eight right, cleared
for takeoff, make right closed traffic."* The side comes from the airport's own traffic
pattern data (`1101` rows in `apt.dat`, the active runway's flow first); with none on
file, it defaults to **left**, the standard direction (AIM 4-3-3).

## The circuit

Once you're airborne (not just cleared -- actually off the ground), the phase becomes
**PATTERN** -- there's no Departure handoff for pattern work, you stay with Tower the
whole time. Climbing through 40% of the way to pattern altitude -- 400 ft AGL for a
piston, 600 ft for a turbine or jet -- Tower says **"report midfield downwind."**

Call it out -- *"midfield right downwind, touch and go"* or *"...full stop"* -- and
Tower replies, sequencing you behind anyone ahead of you in the pattern or on the runway
(M7-3, fed by the [live traffic feed](traffic-advisories.md)):

- **Traffic ahead of you in the pattern**: *"number two, follow the Cessna on
  downwind"* -- or "number three," "number four," counting everyone ahead of you, not
  just the nearest -- report it in sight the same way [Approach's own sequencing
  call](../roadmap.md#m7-traffic-awareness) works, and your landing clearance waits
  until the one you're following has landed or gone.
- **Nothing ahead of you, but the runway itself is still occupied**: *"number one,
  continue"* -- try again next time around.
- **Otherwise, a touch-and-go, stop-and-go, or "the option"**: *"number one, runway two
  eight right, cleared for the option,"* or, for **a full stop** (the default if you
  don't say otherwise), *"...cleared to land."* Either way, **"caution wake
  turbulence"** folds in (F11, F12) behind a Heavy or Super that used the runway
  recently.

A touch-and-go's landing clearance lapses the moment you're airborne again, and the next
circuit starts fresh -- Tower asks for another midfield downwind report, and you need a
fresh landing clearance before touching down again.

After a full stop, once you're clear of the runway, you're handed to the field's own
Ground the same way any arrival is: *"contact Portland Ground one two one point niner."*
Phase becomes TAXI_IN from there, same as any other arrival.

## Conformance in the pattern

A dedicated pattern monitor runs alongside the usual [conformance
monitor](conformance-monitor.md), spoken from Tower:

| Rule | Fires when | Ladder |
|---|---|---|
| **Pattern altitude** | More than the tolerance (200 ft at normal strictness) off field elevation + **1,000 ft AGL for a piston, 1,500 ft for a turbine or jet** (by ICAO type designator; unknown types default to piston), once established at it this circuit -- suspended once you're cleared to land, so climb-out and the descent to land don't trigger it | *"check altitude, pattern altitude one thousand"* → *"maintain pattern altitude, one thousand"* → "possible pilot deviation" |
| **Leaving the pattern** | Farther than the pattern limit from the airport (3 nm normal, 4 relaxed, 2.5 checkride) with no call | *"say intentions"* → "possible pilot deviation" (no gentler first step) |
| **Landing without a clearance** | Touching down in the pattern without a landing clearance on file -- the same rule an [arrival](arrival.md) landing without clearance gets | Straight to "possible pilot deviation" |

## Squawk

VFR pattern work squawks **1200**, and since there's no assigned IFR code to compare
against, the [wrong-squawk conformance rule](conformance-monitor.md#airborne-conformance)
never fires.

## Out of scope

- **Non-towered fields.** Pattern work needs a Tower; there's no CTAF self-announce
  handling for an untowered airport.

A Class D field's own [Class B/C/D airspace entry](vfr-airspace-entry.md) rules apply
here too, since that mechanism isn't gated to a particular flight phase -- though the
combination isn't specifically covered by a test.

A VFR flight whose destination is a *different* airport doesn't fly the pattern at all
-- see [VFR flight following](vfr-flight-following.md).
