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

A new ATIS letter is issued when any of these change versus the previous broadcast:

- flight category (VFR/MVFR/IFR/LIFR), including becoming or stopping being unreported
- wind direction shifts 30° or more
- wind or gust speed changes 10 kt or more
- altimeter changes 0.06 inHg (~2 hPa) or more
- visibility changes 2 SM or more (when both readings report it)

This is a simplified approximation of the FAA's real significant-change rule set, not
the full rule.

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
  state back (which, like other readbacks, isn't actually checked yet -- see
  [Conformance monitor](conformance-monitor.md)).
