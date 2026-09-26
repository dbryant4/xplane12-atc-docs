# Taxi routing & hold-shorts

**Available now.**

## What it does

`xatc.world.taxigraph` parses the airport's `apt.dat` taxiway network (nodes and edges,
rows 1201/1202/1204) into a graph, and computes a real route from wherever the aircraft
actually is to the hold-short line of the assigned runway when you request taxi on
Ground.

Real example output:

```
"runway one six left, taxi via Bravo, Delta, cross runway one six center,
hold short of runway one six right"
```

or, with no named taxiway segment and no crossings at all: *"...runway one six left,
taxi."*

## How it decides

1. **Starts from the aircraft's live sim position, not a named gate.** There's no ramp
   or gate resolver yet -- see [Fuzzy ramp resolver](fuzzy-ramp-resolver.md) -- so the
   route always snaps to whichever taxi-graph node is geographically closest to wherever
   the aircraft actually is when you ask.
2. **Runway** comes from your existing [IFR clearance](ifr-clearance.md) if you have one
   (so a taxi route always agrees with a prior clearance), or freshly from [runway
   selection](runway-selection.md) if you ask Ground for taxi before ever talking to
   Clearance Delivery.
3. The path is a shortest-path search to the hold-short boundary node nearest the
   runway's own threshold -- not simply the cheapest reachable boundary node in
   general, since the nearest-looking one can be surrounded entirely by hold-short
   edges and genuinely unreachable without crossing something.
4. Runway pavement is strongly discouraged (a large routing penalty) rather than
   forbidden outright, so a route can still cross a runway when that's genuinely the
   only way to reach the assigned one.
5. The resolved path is collapsed into named taxiway segments, and every runway crossing
   along the way becomes a spoken clause -- "cross runway X" for a runway you cross on
   the way, "hold short of runway Y" for the destination. If a hold-short row in apt.dat
   only names one physical end of a crossed runway, both ends are covered so the same
   physical runway is never reported as crossed twice, even if apt.dat splits it across
   multiple edges.
6. Which physical end of a crossed runway gets spoken matches the flow family of the
   assigned runway -- an aircraft routed to 16L crossing "16C/34C" is told to cross
   **16C**, not 34C, since that's the end actually in the flow of traffic it's part of.
   This resolution is now robust to an `apt.dat` file that spells the same runway
   inconsistently between its own row and its hold-short rows (e.g. KLAX's "6R" vs.
   "06R") -- runway ids are canonicalized everywhere this logic looks them up, fixing a
   real bug that could name the wrong physical end at a handful of real airports.

Arrival at the hold-short line is detected once the aircraft comes within about 30
meters of the route's last node -- this is proximity detection for advancing the flight
phase, not conformance monitoring (it doesn't check whether you actually followed the
assigned route to get there).

### Runway requests to Ground

You can ask Ground for a specific departure runway instead of taking the one already
selected. If the wind still allows it -- within the same tailwind/crosswind limits [runway
selection](runway-selection.md) itself enforces -- Ground approves it and issues a fresh
taxi route to the new runway. If the wind doesn't allow it, you get *"unable runway
two five left, wind"* instead and keep the runway you already had.

## Configuration

None -- routing is entirely derived from the airport's own taxiway data.

## Limitations

- No dedicated hold-short-to-threshold leg for line-up-and-wait.
- No ramp/gate-name resolver -- see [Fuzzy ramp resolver](fuzzy-ramp-resolver.md).

[Pushback](pushback.md) and taxi-in (runway exit back to a gate, on arrival) are both
real now -- this page's older limitations bullets for them are gone.
