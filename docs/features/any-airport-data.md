# Any-airport data loading

**Available now: locating and reading a real X-Plane install's own data files. In
progress: the engine still only ever departs KSEA -- wiring this data into airport and
Center selection is separate, ongoing work.**

The MVP was scoped to KSEA only, with `xatc` developed and run from a Mac, reaching
X-Plane's Web API on a separate Windows PC over an SSH tunnel. The owner has since
approved making `xatc` fly any airport its scenery covers, which needs real airport data
(apt.dat) and real Center airspace data (atc.dat) for wherever the aircraft actually is
-- data that only exists inside a real X-Plane installation, not in this repo's small
fixture set. See ADR 0006 in the repository for the full decision record.

## What exists today

`xatc.world.xplane_data` -- read-only and side-effect-free except for its own cache
directory, never touches anything inside the X-Plane installation itself:

- **`find_xplane_root`**: an explicit `--xplane-root`, or auto-detected on Windows from
  `%LOCALAPPDATA%\x-plane_install_12.txt` (the file X-Plane itself writes on every
  successful launch; the last valid line wins). Not gated on the running OS -- it simply
  reads an environment variable that happens to only be set on Windows, so it naturally
  no-ops elsewhere. Falls back to this repo's bundled KSEA/ZSE fixtures, exactly as
  before this existed, whenever no install is given or found -- so Mac/Linux development
  and CI are unaffected either way.
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
  against the installation's own `atc.dat` Center airspace blocks -- geometry only, no
  frequency selection (that stays a separate concern).
- **Spoken airport names**: derived from an apt.dat header name (`Intl` → `International`,
  `Rgnl` → `Regional`, `Muni` → `Municipal`, and similar), with the existing hand-verified
  name table still taking priority for the airports it already covers.

`xatc run --xplane-root` resolves `--apt-dat`/`--atc-dat` from a found install
automatically when neither is given explicitly, falling back to the bundled fixtures
exactly as before otherwise.

## What isn't wired up yet

The engine itself hasn't changed: `xatc run` still always departs **KSEA**, and the
Center handoff still always targets **Seattle Center (KZSE)**, both hardcoded. Making
those choices dynamically -- picking a departure airport from `nearest_airport` (plus a
`--departure` override), and the Center facility from `artcc_for_position` -- is separate,
ongoing follow-up work, along with proving the pieces that touch station naming and
magnetic variation against a second real airport fixture instead of only KSEA's.

## Verification

Tested against fake X-Plane installation trees built under a temp directory in every
test -- scenery-pack priority and the disabled/marker-line handling, cache
invalidation on file mtime, nearest-airport selection by great-circle distance, and
`artcc_for_position` against the project's real Seattle Center fixture data (known
in-boundary and out-of-boundary points, altitude banding). The one genuinely
Windows-specific case (parsing a Windows-style install-marker path) runs on CI's
Windows job; the LOCALAPPDATA-driven detection logic itself runs on every platform.
