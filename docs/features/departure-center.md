# Departure & Center

**Available now**, through initial enroute climb.

## Departure

Once [Tower hands you off](controller-positions.md#handoffs) above 1,000 ft AGL and you
check in on Departure's frequency, you get:

```
"Seattle Departure, radar contact, climb and maintain one zero thousand"
```

The climb altitude is capped at 10,000 ft (or your filed cruise altitude, if that's
lower) -- a real Departure climbs an aircraft in steps toward its filed altitude, which
this engine doesn't model yet; it assigns one capped initial climb and stops there. This
also advances the flight phase to `DEPARTURE`.

## Departure hands off to Center

As the climb nears that same capped altitude (9,000 ft MSL), Departure hands you off to
Center:

```
"contact Seattle Center one two eight point three"
```

The Center **facility** is found from the aircraft's actual position
(`xatc.world.xplane_data.artcc_for_position`, point-in-polygon containment against
`atc.dat`'s own Center airspace blocks -- see [Any-airport data
loading](any-airport-data.md)), not hardcoded to any one ARTCC. Its **frequency** then
comes from `xatc.atc.center_selector.select_center_frequency` -- a documented placeholder
rule (ADR 0003), since `atc.dat` doesn't actually encode real sector-to-frequency
subdivisions within a block: it picks a frequency by a bearing wedge from the block's
polygon centroid to the aircraft's position, not real controller sector geometry. If no
Center block covers the aircraft's position at all, the handoff simply doesn't fire and
the aircraft stays on Departure rather than guessing at a frequency.

**The Center controller position is created dynamically**, the moment the handoff
fires -- unlike ATIS/Clearance/Ground/Tower/Departure, which all come from the
airport's own `apt.dat` rows, there's no static "Center position" sitting around ahead
of time. Its frequency, facility id, and callsign (e.g. "Seattle Center") all come from
whichever `atc.dat` controller block the frequency-selection rule actually matched.

Checking in on Center gets:

```
"climb and maintain one eight thousand"    (below FL180)
"climb and maintain flight level three five zero"    (at or above 18,000 ft)
```

-- your full filed cruise altitude this time, not a capped one, and it advances the
flight phase to `ENROUTE`.

**Check-ins are only accepted after a real handoff actually happened** -- being in the
right phase isn't enough by itself. The engine also checks that
`Clearance.expected_next_freq_khz` still points at the exact frequency you're checking
in on, so a check-in transmission heard too early (before Departure's own handoff has
fired) doesn't jump the phase; it gets "say again" instead.

## Configuration

```bash
xatc run --departure KPDX --atc-dat <path>   # an explicit atc.dat needs --departure too
```

See [Any-airport data loading](any-airport-data.md) for the full precedence
(`--apt-dat`/`--atc-dat`, then an X-Plane install via `--xplane-root`, then the bundled
fixtures) and how the departure airport itself is chosen.

## Limitations

- No step climbs beyond the two capped handoff altitudes (Departure's 10,000 ft cap,
  then straight to full cruise at Center) -- a real Departure/Center climbs an aircraft
  incrementally.
- No direct-to clearances, crossing restrictions, or "descend via the STAR" calls --
  Center's only current behavior is the initial check-in climb.
- The Center frequency-selection rule is a deterministic placeholder (a bearing wedge),
  not real ARTCC sector geometry -- there's no source data for actual sector boundaries
  in `atc.dat`.
- No arrival or approach logic yet at all -- see the [Roadmap](../roadmap.md).
