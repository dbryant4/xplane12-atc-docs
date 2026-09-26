# ATIS & weather from the sim

**Available now.**

## What it does

All weather comes **from X-Plane itself** -- there are no external weather calls -- so
ATC always matches whatever you're actually flying in, real weather or custom weather.
`xatc.weather.service` reads the sim's own weather datarefs, converts them into a
`WeatherSnapshot` (wind, altimeter, ceiling, visibility, temperature, flight category),
and generates a looping ATIS broadcast with an information letter that advances only
when the weather actually changes.

## Example output

```
Seattle-Tacoma International information Alpha. Wind one eight zero at one zero.
Visibility one zero. Sky clear. Temperature one five, dew point eight.
Altimeter two niner niner two. Landing and departing runway one six left.
Advise on initial contact you have information Alpha.
```

Wind is spoken as **magnetic**, converted from the sim's true-heading data using the
aircraft's own true/magnetic heading gap (there's no separate magnetic-variation
dataref this reads). The active runway comes straight from [runway
selection](runway-selection.md), so the ATIS and what Clearance/Ground actually assign
never disagree.

## How it decides when to advance the letter

A live KPDX flight found the original version of this rule too twitchy -- a cloud layer
hovering right at an okta-coverage boundary flickered the reported ceiling by a couple
hundred feet every few ticks, and each flicker read as a real flight-category change,
advancing the letter every couple of minutes. `AtisGenerator` now smooths the ceiling
(a ~2-minute rolling window: a majority vote on whether there's a ceiling at all, then
the median height among the readings that have one, rounded to the nearest 100 ft) before
comparing anything, and `is_significant_change` itself compares against *thresholds a
reading has crossed*, not the raw values:

- flight category (VFR/MVFR/IFR/LIFR) changes, including becoming or stopping being
  unreported
- the smoothed ceiling crosses 500, 1,000 or 3,000 ft AGL (in either direction -- gaining
  or losing a ceiling reading entirely counts too)
- visibility crosses 1 or 3 SM (when both readings report it)
- wind direction shifts 30° or more, but only while the wind is 10 kt or more -- a
  near-calm or variable direction is too noisy to mean anything operationally
- wind speed changes 10 kt or more
- a gust appears or disappears altogether, or changes by 10 kt or more once already
  present
- altimeter changes 0.02 inHg or more
- the active runway changes

Comparisons are always against the reading the letter last actually advanced on, not the
immediately-previous call -- so a slow drift (altimeter creeping up 0.01 inHg at a time)
still eventually crosses a threshold instead of resetting every step and never
accumulating. Absent any of the above, the letter still advances once an hour, matching
how a real ATIS keeps pace even when nothing operationally significant has happened.

This is a simplified approximation of the FAA's real significant-change rule set, not
the full rule.

## Range

ATIS is only heard within 60 nm of the airport broadcasting it -- tuning an ATIS
frequency from farther out gets silence, matching a real D-ATIS-equivalent service
volume, instead of pulling in a broadcast from an airport nowhere near the flight.

## Where the numbers come from

- **Near the aircraft** (on the ground, or near the destination once close): sim weather
  datarefs directly -- wind, visibility, and altimeter at the aircraft's own position,
  and cloud layers/wind by altitude from the sim's regional data.
- **A distant airport** (the arrival ATIS while still enroute): X-Plane's own real-weather
  METAR file, if it's running in real-weather mode and has downloaded one -- read
  directly off disk. In custom-weather mode there's no METAR file, so this falls back to
  the regional datarefs once you're close enough, filling in only what a METAR would
  have been missing (visibility) rather than overriding a real METAR's own numbers with
  guessed regional data.

## Runway hysteresis

A related fix from the same KPDX flight: the active runway itself flickered between
28R/28L on a wind reading of "variable at two," since [runway
selection](runway-selection.md) is a pure, stateless function that answers fresh from
whatever the sim reports each call, with nothing remembering what it picked last time.
`xatc.atc.runway_selector.RunwaySelector` wraps it with hysteresis -- a calm or variable
reading never causes a switch away from the current runway, and any other new answer has
to keep coming back the same way for a few minutes before it's adopted, except when the
*current* runway has drifted beyond its tailwind or crosswind limit, which switches at
once rather than waiting out the sustain window (a stale runway shouldn't get a takeoff
clearance).

**This class is implemented and tested, but the engine doesn't use it yet** -- all three
places `engine.py` picks a runway still call the bare `select_runways` directly, so the
live engine doesn't currently get the hysteresis benefit described here; only the ATIS
letter's own smoothing (above) is wired in from that flight.

## Configuration

`xatc run --replay ... --weather-fixture {north-flow,south-flow}` seeds a fixed
weather snapshot for development without a live sim; `--live` mode always reads real
sim weather continuously instead.

## Limitations

- Flight category and significant-change detection are simplified approximations, not
  the FAA's full published rule set.
- No plugin-based weather API fallback (`XPLMGetMETARForAirport`) -- only datarefs and
  the METAR file.
- ATIS is delivered as a looping voice broadcast on its own frequency; it isn't
  currently woven into what Clearance/Ground/Tower say beyond confirming the letter you
  state back.
- `RunwaySelector`'s hysteresis (above) isn't wired into the live engine yet.
