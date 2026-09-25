# Runway selection

**Available now** (for KSEA).

## What it does

`xatc.atc.runway_selector.select_runways` picks which runway is active for arrivals and
departures, and which approach type fits the weather -- used everywhere the engine needs
an active runway: the [ATIS broadcast](atis-weather.md), an [IFR
clearance](ifr-clearance.md), and [taxi routing](taxi-routing.md). It's computed fresh
from the current weather every time it's needed, not cached per aircraft -- it's a
field-wide fact, not private state.

## How it decides

1. **Flow rules first.** Walk the airport's `apt.dat`-defined traffic flows (rows
   1000-1004, 1110) in file order and use the first one whose wind/ceiling/visibility
   rules match -- rule *kinds* are ANDed together, but multiple rules of the same kind
   (e.g. two wind arcs) only need one to match. Wind direction is converted from true to
   magnetic first, since apt.dat's flow arcs are magnetic.
2. Within the matched flow, pick the runway assigned to the aircraft's category
   (jets/heavy/turboprops/props) for the direction needed (arrival or departure).
3. **Wind-based fallback**, only if no flow matched at all: compute headwind/crosswind
   for every runway end from real threshold geometry (not guessed from the runway
   number), exclude ends over 10 kt tailwind or 20 kt crosswind, and pick the one with
   the most headwind. Calm or no-match conditions deterministically fall back to the
   airport's first runway end rather than guessing.
4. **Approach type**: `VISUAL` if the ceiling is at least 1,000 ft AGL and visibility at
   least 3 SM; `RNAV` if visibility or sky condition wasn't reported at all; `ILS`
   otherwise. This is a simplified generic minimums check, not real published approach
   minima for any specific procedure.

Real KSEA example (from the project's own fixture): calm wind or wind from
070°-250° selects the "Calm and South flow," giving 16L for jets on departure; wind from
250°-070° selects "North flow," giving 34R.

## Configuration

Tailwind/crosswind limits (10 kt / 20 kt) are module constants, not exposed as flags.
Magnetic variation for the wind-to-runway comparison is currently a hardcoded
KSEA-specific constant -- the selector can't run correctly at another airport without
that being supplied some other way.

## Limitations

- Aircraft category comes from a small hand-authored ICAO-type table; unknown types
  default to "jets."
- No time-of-day (row 1004) rule enforcement, even though those rows are parsed.
- Approach-type selection is a simplified generic check, not real minima for a specific
  published procedure -- there's no CIFP approach-procedure parser behind it.
- Magnetic variation is a hardcoded constant for one airport.
