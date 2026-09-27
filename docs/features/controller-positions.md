# Controller positions & frequencies

**Available now** (ATIS, Clearance, Ground, Tower, Departure, Approach, Center, and the
full gate-to-gate handoff chain -- see [Departure & Center](departure-center.md) and
[Arrival](arrival.md)).

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
frequency itself is chosen, Center-to-Center handoffs across a real ARTCC boundary, and
why check-ins are only accepted after a handoff has actually fired. The same handoff
chain continues through arrival -- Center to Approach, Approach to Tower, Tower to
Ground -- see [Arrival](arrival.md).

### Check-in reminders

Every handoff above -- including the one a go-around triggers -- now expects a check-in.
Go 60 seconds without one on the new frequency and the position that handed you off
tries again:

```
"are you with me? contact Seattle Departure one one niner point two"
```

Silence for another 60 seconds gets one more, more urgent, repeat of the same call.
After two reminders, nothing further -- there's no lost-comm procedure. Checking in (or,
on Ground, simply making a taxi request) on the new frequency cancels any reminder still
pending. The second unanswered reminder also raises a `NO_CHECKIN` event
(`xatc.atc.conformance_core.RadioRule`), recorded in the [post-flight
debrief](debrief.md)'s Deviations section the same way a real conformance call would be,
even though it isn't produced by any of the three [conformance
monitors](conformance-monitor.md) -- the engine raises it itself, the moment it re-sends
the second reminder.

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

## Directory ordering (F14)

The [radio panel](radio-panel.md)'s frequency directory follows the aircraft, most
relevant first:

1. **The controller working you now** (marked), then **the one you're expected to check
   in with next** (marked, with the one-click "Load & swap" from [Handoffs](#handoffs)
   above) -- Center included, so a handoff between two sectors of the same ARTCC still
   gets its own row even though both share one callsign/id.
2. **The departure airport's positions** while you're within 40 nm of it, and **the
   destination's** within 60 nm (both groups show if both are close; the destination's
   group comes first once you've arrived), each in the same per-phase order as before
   (ATIS, Clearance, Ground, Tower before taxi; Tower first once holding short or
   cleared for takeoff).
3. **The Center sector you're actually in**, once you're above ~3,000 ft AGL or en route
   -- this is what fills in the gap the old static table left once you're too far from
   either airport for its own positions to show.
4. **Other airports' Tower, CTAF/UNICOM and ATIS/ASOS/AWOS** within 30 nm, nearest
   first, each row showing its distance ("12 nm"). Only land airports -- heliports and
   seaplane bases are never listed. These load in the background (a fresh apt.dat parse
   the first time an airport's frequencies are needed), so they can take a few seconds
   to actually appear rather than showing instantly with the rest of the directory.

Rebuilt at most every 5 seconds of sim time, or at once when the phase or the
working/next controller changes.

## Configuration

The airport-based positions come from `apt.dat`, and Center's frequency selection from
`atc.dat` -- see [Any-airport data loading](any-airport-data.md) for how `xatc` picks
which airport and `atc.dat` to actually read (`--departure`, `--apt-dat`, `--atc-dat`,
`--xplane-root`, in that precedence).

## Limitations

- No lost-comm procedure -- two unanswered check-in reminders and the engine simply
  stops calling (see above).
- Redirects only cover three intents; everything else on a wrong staffed frequency is
  silence, not a redirect.
- Which position owns you never depends on other traffic -- position/frequency
  resolution is a flat scan over `frequencies_khz`, nothing else. [Sequencing behind
  other traffic](../roadmap.md#m7-traffic-awareness) (M7-3, fed by the live traffic
  feed) is a separate mechanism layered on top of this, on approach and in the VFR
  pattern -- it changes when a clearance comes, never who you're talking to.
