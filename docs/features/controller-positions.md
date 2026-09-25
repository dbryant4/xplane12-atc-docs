# Controller positions & frequencies

**Available now** (ATIS, Clearance, Ground, Tower, Departure, Center, and the
Tower→Departure→Center handoff chain). **Approach: still planned** -- see [Departure &
Center](departure-center.md).

## What it does

`xatc.atc.positions.build_positions` turns an airport's parsed `apt.dat` frequency rows
into one `ControllerPosition` per facility kind it finds: ATIS, Clearance, Ground,
Tower, and (from row 1056, no `atc.dat` needed) Departure. Each position gets a stable
id (`KSEA_GND`, `KSEA_TWR`, ...) and a callsign built from the airport's own name plus
the position type -- "Seattle Ground", "Seattle Tower", "Seattle Clearance", derived
from the first word of KSEA's apt.dat name ("Seattle-Tacoma Intl").

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

`apt.dat`/`--apt-dat` for the airport-based positions; `atc.dat`/`--atc-dat` for
Center's frequency selection. Both default to bundled fixtures.

## Limitations

- No Approach position or arrival logic exists yet -- see [Departure &
  Center](departure-center.md).
- No "are you with me?" reminder if you never check in after a handoff, and no lost-comm
  behavior.
- Redirects only cover three intents; everything else on a wrong staffed frequency is
  silence, not a redirect.
- Single aircraft only -- there's no sequencing or traffic awareness in who owns you.
