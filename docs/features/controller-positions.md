# Controller positions & frequencies

**Available now** (ATIS, Clearance, Ground, Tower, Departure, Approach, Center, and the
Tower→Departure→Center handoff chain). Approach appears in the frequency directory when
an airport's own `apt.dat` provides one, but nothing routes traffic through it yet -- see
[Departure & Center](departure-center.md).

## What it does

`xatc.atc.positions.build_positions` turns an airport's parsed `apt.dat` frequency rows
into one `ControllerPosition` per facility kind it finds: ATIS, Clearance, Ground,
Tower, Departure (row 1056) and Approach (row 1055) -- no `atc.dat` needed for any of
these. A combined "APP/DEP" row supplies whichever of Departure/Approach the airport's
own rows don't otherwise give it. Each position gets a stable id (`KSEA_GND`,
`KSEA_TWR`, ...) and a callsign built from that frequency row's own name where one is
readable (role words and the airport's own identifier stripped, with a couple of casing
fixups like NorCal/SoCal), falling back to the first word of the airport's own apt.dat
name otherwise -- "Seattle Ground", "Seattle Tower", "Seattle Clearance" for KSEA.

**Center is different**: it isn't in that static, apt.dat-derived set at all. It's
created dynamically, the moment Departure hands off to it, from a parsed `atc.dat` (the
`--atc-dat` flag) instead of `apt.dat` -- see [Departure &
Center](departure-center.md#departure-hands-off-to-center).

**Which frequency you're on is the entire model of who's listening.** The engine
resolves the owning position with a flat scan over each position's `frequencies_khz` --
there's no airspace geometry involved. Tune the wrong frequency and you get silence,
exactly like the real thing.

## Handoffs

Tower initiates a handoff to Departure automatically, in `on_tick`, once the aircraft is
airborne and above 1,000 ft AGL:

```
"contact Seattle Departure one one niner point two"
```

This sets `Clearance.expected_next_freq_khz` to Departure's frequency -- which is also
what the [radio panel](radio-panel.md) uses to highlight that entry in the frequency
directory with a one-click "Load & swap" button. The handoff fires exactly once (guarded
by that same field already being set) and won't repeat on later ticks. Checking in on
Departure's frequency clears it back to `None` and gets:

```
"Seattle Departure, radar contact, climb and maintain one zero thousand"
```

(capped at 10,000 ft for this MVP+, or your filed cruise altitude if it's lower -- a
real Departure climbs you in steps, which isn't modeled yet).

Departure hands off to Center the same way, once you're near that capped altitude --
see [Departure & Center](departure-center.md) for the details, including how the Center
frequency itself is chosen and why check-ins are only accepted after a handoff has
actually fired.

## Wrong-frequency redirects

If you ask for something on the wrong *staffed* frequency -- request an IFR clearance on
Ground, say, instead of Clearance -- the engine redirects you to whoever actually owns
that request:

```
"contact Seattle Clearance one two eight point zero"
```

This covers three intents today: an IFR clearance request, a taxi request, and
"ready for departure." Anything else on a wrong-but-staffed frequency currently falls
through to silence rather than a redirect.

## Directory ordering

The [radio panel](radio-panel.md)'s frequency directory is sorted by a small
per-phase table -- e.g. on the ground before taxi it's ATIS, Clearance, Ground, Tower;
once you're holding short or cleared for takeoff, Tower moves to the top. It's a static
table keyed on `Phase`, not a real distance/relevance calculation.

## Configuration

The airport-based positions come from `apt.dat`, and Center's frequency selection from
`atc.dat` -- see [Any-airport data loading](any-airport-data.md) for how `xatc` picks
which airport and `atc.dat` to actually read (`--departure`, `--apt-dat`, `--atc-dat`,
`--xplane-root`, in that precedence).

## Limitations

- **No arrival or approach logic.** An Approach position exists in the frequency
  directory once apt.dat provides one, but nothing routes traffic through it -- no
  vectors, sequencing, approach clearance, or landing clearance yet. See [Any-airport
  data loading](any-airport-data.md) and the [Roadmap](../roadmap.md).
- No "are you with me?" reminder if you never check in after a handoff, and no lost-comm
  behavior.
- Redirects only cover three intents; everything else on a wrong staffed frequency is
  silence, not a redirect.
- Single aircraft only -- there's no sequencing or traffic awareness in who owns you.
