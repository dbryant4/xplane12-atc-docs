# Readback checking

**Available now.**

## What it does

Pilot readbacks are now actually checked against what ATC issued, instead of always
being accepted. Miss a required item and you get corrected:

```
negative, climb and maintain five thousand
```

```
read back hold short instructions
```

Get it right, and you get the standard confirmation, restating anything you were only
*warned* about leaving out (not required, but worth a reminder):

```
readback correct, departure frequency one one niner point two
```

## What's checked, and how strictly

`xatc.phraseology.readback.check_readback(issued, kind, pilot_text)` compares a pilot's
transmission against the `Clearance` ATC actually issued, for six kinds of instruction:
`ifr_clearance`, `taxi`, `takeoff`, `altitude`, `heading`, `frequency`. Each kind has its
own required-vs-warning breakdown -- for example, an IFR clearance readback *must*
include the altitude and squawk code, but the clearance limit, SID, and departure
frequency are only warned about if missing, not rejected outright. A taxi readback must
include the assigned runway and *every* hold-short instruction it was given, but the
full taxi route itself is only a warning.

The checker tolerates real ASR quirks rather than demanding an exact transcript: common
homophones (*tree/fife/niner/won/fower* for digits), abbreviated forms ("one six left"
without the word "runway", "maintain five" for 5,000 ft, a frequency without the leading
"one", "cleared as filed"), and digit words that only mean a number right after another
digit (*"two to fower"* meaning 2-to-4, not "two two four").

## How it's wired into the engine

Issuing an IFR clearance or a taxi clearance now sets a **pending readback** that has to
be satisfied before the flight can actually advance -- the phase change (to `CLEARANCE`
or `TAXI_OUT`) doesn't happen until the readback is correct. Altitude and frequency
instructions are also readback-checked, but don't gate a phase change on their own. A
takeoff clearance is deliberately **not** readback-checked.

Get it wrong, and the clearance stays pending -- ATC doesn't just move on, but it also
doesn't automatically repeat the whole clearance verbatim; the correction only restates
what was missing or wrong. If you reach the hold-short point with a taxi readback still
outstanding, Ground proactively asks for it once, rather than letting things fall
through to a plain "say again" at the runway.

## Limitations

- **No "relaxed" mode yet.** The plan is for a relaxed conformance-strictness setting to
  still restate a readback problem without holding up the flight over it -- that's
  designed but not built.
- Only the six kinds above are checked; nothing else (e.g. a wrong-frequency
  acknowledgment) is readback-verified.
- Takeoff clearances are exempt by design, not an oversight -- a real "cleared for
  takeoff" readback is short enough that a full check adds little value over what the
  runway-incursion rule in the [conformance monitor](conformance-monitor.md) already
  catches.

## Verification

Unit tests cover the ASR normalization rules and each readback kind's required/warning
split directly, plus extensive coverage threaded through the engine's own test suite --
confirming a wrong or incomplete readback actually blocks the phase advance, a correct
one advances it and restates any warned-about omission, and the hold-short reminder
fires when a taxi readback was never corrected.
