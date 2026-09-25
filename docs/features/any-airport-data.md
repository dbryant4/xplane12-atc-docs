# Any-airport data loading

**Available now: `xatc` flies any airport its scenery (or the bundled fixtures) covers,
not just KSEA.**

The MVP was scoped to KSEA only, with `xatc` developed and run from a Mac, reaching
X-Plane's Web API on a separate Windows PC over an SSH tunnel. The owner approved making
`xatc` fly any airport its scenery covers, which needs real airport data (apt.dat) and
real Center airspace data (atc.dat) for wherever the aircraft actually is -- data that
only exists inside a real X-Plane installation, not in this repo's small fixture set.
See ADR 0006 in the repository for the full decision record.

## Locating and reading the data

`xatc.world.xplane_data` -- read-only and side-effect-free except for its own cache
directory, never touches anything inside the X-Plane installation itself:

- **`find_xplane_root`**: an explicit `--xplane-root`, or auto-detected on Windows from
  `%LOCALAPPDATA%\x-plane_install_12.txt` (the file X-Plane itself writes on every
  successful launch; the last valid line wins). Not gated on the running OS -- it simply
  reads an environment variable that happens to only be set on Windows, so it naturally
  no-ops elsewhere. Falls back to this repo's bundled fixtures, whenever no install is
  given or found -- so Mac/Linux development and CI are unaffected either way.
- **Airport lookup**: `Custom Scenery/scenery_packs.ini`, in priority order, honoring the
  `SCENERY_PACK *GLOBAL_AIRPORTS*` marker's actual position -- a pack listed after that
  marker loses to Global Scenery for an ICAO both define, not simply "packs always beat
  Global." The apt.dat that actually defines an ICAO is streamed one airport at a time
  (never the whole, often ~300 MB, file) and cached per source file (path, mtime, size)
  under `platformdirs`' cache directory.
- **`nearest_airport(lat, lon)`**: backed by a one-time, lightweight header-only index
  across all of scenery (ICAO plus reference lat/lon from apt.dat's 1302 datum rows,
  falling back to the first runway's coordinates for older-format scenery), cached the
  same way.
- **`artcc_for_position(controllers, lat, lon, alt_ft)`**: point-in-polygon containment
  against the installation's own `atc.dat` Center airspace blocks, at the altitude ATC
  actually judges conformance on (see [Conformance monitor](conformance-monitor.md)).
- **Spoken airport names**: derived from an apt.dat header name (`Intl` → `International`,
  `Rgnl` → `Regional`, `Muni` → `Municipal`, and similar), with a small hand-verified name
  table taking priority for the airports it already covers.

## Flying from wherever the aircraft actually is

The engine no longer hardcodes KSEA or Seattle Center:

- **Departure airport**: `--departure ICAO`, or by default the airport nearest the
  aircraft's first sim position -- the first recorded state with `--replay`, or the first
  live tick with `--live` (in which case the engine itself is built lazily, once that
  first position is known). An unknown departure ICAO is a clean startup error.
- **Center**: found by the aircraft's actual position (`artcc_for_position`) instead of
  always Seattle, with its frequency picked by the existing `select_center_frequency`
  and its callsign taken straight from `atc.dat`'s own facility name.
- **Magnetic variation**: derived live from the aircraft's own true/magnetic heading gap
  instead of a fixed constant, smoothed with a time-based moving average so it's
  independent of tick rate. Runway selection uses this live value.
- **Station names**: built from each frequency row's own name in apt.dat, not a fixed
  table -- role words (Ground, Tower, Approach, Departure, D-ATIS, and their spelled-out
  forms) and the airport's own identifier are stripped from the row, with a couple of
  known casing fixups (NorCal, SoCal). A combined "APP/DEP" row supplies whichever of
  Approach/Departure the airport's apt.dat doesn't give its own row.
- **Data source precedence**, for both airports and `atc.dat`: an explicit `--apt-dat`/
  `--atc-dat` first, then the X-Plane install (`--xplane-root`, or auto-detected), then
  the bundled fixtures. Because an explicit `--apt-dat` might not be the airport nearest
  the aircraft, `--apt-dat` requires `--departure` alongside it, to say which airport to
  actually load from it.

## Verification

Tested against fake X-Plane installation trees for the data-loading layer itself --
scenery-pack priority and the disabled/marker-line handling, cache invalidation on file
mtime, nearest-airport selection by great-circle distance, and `artcc_for_position`
against the project's real Seattle Center fixture data. The one genuinely
Windows-specific case (parsing a Windows-style install-marker path) runs on CI's Windows
job; the LOCALAPPDATA-driven detection logic itself runs on every platform.

The engine-level generalization is verified end to end against a second real airport, a
Portland (KPDX) apt.dat fixture pulled from the X-Plane Scenery Gateway: the full
position set and callsigns (including an "APP/DEP" row supplying both Departure and
Approach), flow-rule-based runway selection in both directions, taxi routing (which
exposed and fixed a real bug -- KPDX's crosswind runway is "3"/"21" in its runway row but
"03" in its taxiway hold-short rows, now matched with leading zeros ignored), Center
correctly resolving to Seattle over Portland, and a full ATIS-to-taxi run with live
magnetic variation and spoken airport names. Every existing KSEA test still passes
unchanged, aside from one expectation gaining a new Approach position KSEA's own apt.dat
data always supported but nothing built before.
