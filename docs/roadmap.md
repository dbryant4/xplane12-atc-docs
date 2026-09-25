# Roadmap

## Where things stand

The original MVP goal was ground ops at one airport, by voice: ATIS through a taxi
clearance to hold-short at KSEA. That's done, and the project has since pushed past it
into the departure phase:

- ATIS, IFR clearance (CRAFT), taxi routing with hold-shorts, and wrong-frequency
  silence -- the original MVP scope.
- Tower's takeoff clearance, and a full handoff chain once airborne: Tower to
  Departure (radar contact, an initial climb), then Departure to Center (a dynamically
  created position, its frequency chosen from `atc.dat`) once near that capped
  altitude, ending with an initial enroute climb to full cruise.
- Full push-to-talk voice (Transcribe, Polly, the VHF radio effect) replacing the
  original plan's Nova 2 Sonic speech-to-speech design (see ADR 0004 in the repository)
  -- Polly speaks a clearance exactly as written, removing an entire class of "did the
  model paraphrase this" risk.
- A radio panel with live phase/clearance display, handoff highlighting, and a working
  options screen for switching [intent-parsing modes](features/intent-parsing.md) live.
- An optional Nova Lite LLM fallback for understanding unclear transmissions --
  switchable at runtime (disabled / backup / primary), never involved in generating
  what ATC actually says. Fully wired in, not just scaffolding.
- A [conformance monitor](features/conformance-monitor.md), wired into the engine and
  speaking today -- ground rules (taxiing without clearance, straying off the assigned
  route, runway incursions, takeoff without clearance) and airborne rules (altitude,
  heading, speed, squawk against the current clearance), each with a real escalation
  ladder, a shared strictness setting, a selectable altitude source (Mode C by default,
  matching what a real controller's radar shows), and a 91.117(d) heavy-jet speed
  exception -- all adjustable from the radio panel's options screen.
- A [fuzzy ramp/parking resolver](features/fuzzy-ramp-resolver.md) -- understands a
  spoken ramp or gate reference, tolerant of ASR mistakes, weighted by real distance
  from the aircraft. Also not yet connected to anything: [taxi
  routing](features/taxi-routing.md) still always starts from the aircraft's live sim
  position regardless.
- [Any-airport data loading](features/any-airport-data.md) -- `xatc` now flies any
  airport its scenery (or the bundled fixtures) covers: a real X-Plane install's own
  apt.dat/atc.dat, the departure airport nearest the aircraft (or an explicit
  `--departure`), live magnetic variation, station names read from apt.dat instead of a
  fixed table, and Center found by the aircraft's actual position instead of always
  Seattle. Verified end to end against a second real airport (KPDX), not just KSEA.
- **[SID & departure procedures](features/sid-departure-procedures.md)** -- real ARINC
  424 CIFP procedure data (KSEA and KPDX today) lets ATC actually assign a SID and
  transition, spoken by name, instead of only ever echoing your filed one.
- **[Readback checking](features/readback-checking.md)** -- an IFR clearance or taxi
  readback is now checked field by field; get it wrong and you're corrected, not waved
  through, and the flight doesn't advance until it's right.
- **[Distance-based radio realism](features/radio-fx.md#signal-strength-by-distance)** --
  signal strength and dropout probability now scale with distance and line-of-sight to
  the controlling facility, so a distant Center sector sounds noticeably rougher than
  Tower on the ramp.
- **[SimBrief import](features/simbrief-import.md)** (`--simbrief-user`) -- fetches
  callsign, aircraft type, route, cruise altitude and SID straight from a SimBrief OFP,
  instead of the CLI-flag-only flight plan.
- **[Post-flight debrief](features/debrief.md)** (`--debrief-dir`, `xatc debrief`) --
  every transmission, conformance call, and now readback logged to a session file, with
  a Markdown summary (timeline, deviations by severity, readback pass rate and problems)
  written automatically or regenerated on demand.
- **Relaxed-mode readback gating** -- under relaxed conformance strictness, a wrong or
  missing readback item is restated but no longer blocks the flight from advancing, so a
  garbled ASR transcript can't get a pilot stuck in a loop (see [Readback
  checking](features/readback-checking.md)).
- **[Joystick/yoke push-to-talk](features/joystick-ptt.md)** (`--ptt-joystick`, `xatc
  ptt-probe`) -- a hardware PTT button alongside the on-screen button and the browser's
  keyboard binding. Windows only for now.
- **A phraseology audit against FAA JO 7110.65** -- a golden-string test suite citing the
  exact paragraph each piece of wording follows, which caught and fixed two real bugs
  (an airborne conformance callout reading raw digits instead of spoken numbers, and a
  ground callout reading a bare taxiway letter) plus added pronunciation overrides for a
  handful of local fix names that don't read naturally letter by letter -- see [SID &
  departure procedures](features/sid-departure-procedures.md#pronunciation) and
  [Conformance monitor](features/conformance-monitor.md).
- **Windows setup** (`xatc doctor`, `scripts/setup-windows.ps1`, `xatc-run.cmd`) and a
  hands-on **`xatc smoke --live`** check against a real running X-Plane instance (the
  Web API, COM tuning, live weather, a joystick-button watch, and optionally a real
  Polly phrase through the speakers) -- see [Getting
  Started](getting-started.md#running-on-windows).

This closes out the departure-phase milestone in full: ground ops, a full departure and
enroute handoff chain, a real CIFP-assigned SID, and a checked readback, all the way
through the initial enroute climb.

**[Arrivals (M4) are complete](features/arrival.md), gate to gate**, in four slices,
the same pattern the departure phase used (Tower, then Departure, then Center):

- **M4-1: descent and the STAR clearance.** Center starts the aircraft down a little
  before its own top of descent, with a real CIFP-assigned STAR and transition when one
  fits ("descend via the Kratr Three arrival, Buwzo transition") or a plain altitude
  when it doesn't, followed by the destination's ATIS letter and altimeter.
- **M4-2: approach handoff and approach clearance.** Center hands off to the
  destination's Approach position around 40 nm out (or on reaching the STAR's last fix);
  Approach gives the altimeter, then vectors or "expect &lt;approach&gt;", then the
  actual approach clearance (7110.65 4-8-1) once established.
- **M4-3: landing clearance, runway exit, and taxi-in.** Approach hands off to Tower at
  the approach's charted final approach fix; Tower clears to land, with wind (7110.65
  3-10-5); once clear of the runway, Tower hands off to Ground, which taxis to a named
  stand or the nearest gate, with every runway crossing on the way read back the same
  as a taxi-out crossing is.
- **M4-4: go-around and parking.** Call "going around" (or don't -- the landing
  conformance monitor catches an unreported one too) and ATC actually sends you around
  with a real missed-approach clearance, then re-sequences you for another attempt at
  the same approach. Reach your stand with the parking brake set or the engines off and
  the flight goes quiet -- real Ground doesn't say anything when you park.

Two more things landed alongside M4: **check-in reminders** (any handoff -- Tower,
Departure, Center, Approach, Ground, including after a go-around -- gets an "are you
with me?" repeat after 60 seconds of silence, then one more, more urgent, repeat after
another 60; see [Controller positions & frequencies](features/controller-positions.md#check-in-reminders)),
and **Center-to-Center handoffs** (crossing into a genuinely different ARTCC's real
airspace, from `atc.dat`'s own Center polygons, now hands you off across that boundary
instead of staying on one facility for the whole flight -- see [Departure &
Center](features/departure-center.md#center-to-center-handoffs)).

See [Features](features/index.md) for the detailed, per-feature "available now" vs.
"planned" breakdown.

## What's next

Roughly in the order the project is tackling it:

- **M5-1: ATIS-letter check on initial contact** (in review). If the pilot reports an
  outdated ATIS letter (or none at all) when first checking in with Clearance, Ground or
  Approach, ATC adds "information &lt;current&gt; is current, &lt;altimeter&gt;" or
  "advise you have information &lt;X&gt;" (7110.65 2-9-3) -- the letter is already
  tracked, just not checked against yet.
- **M5-2: pilot requests en route.** "Request direct &lt;fix&gt;", "request higher/
  lower", "request flight level &lt;n&gt;", and weather deviations, each with a real
  ATC response instead of going unhandled.
- **M5-3: emergencies and special squawks.** Mayday/pan-pan, and squawks 7700/7600/7500,
  each with the FAA-style response and priority handling this project doesn't model at
  all yet.
- **M5-4: pushback on Ground.** A `PUSHBACK` phase and "push back approved, tail
  &lt;direction&gt;" before taxi, for a gate departure that doesn't already start facing
  out.
- **Wire the fuzzy ramp resolver into taxi routing for departure.** Taxi-*in* (M4-3)
  already resolves a spoken stand; taxi-*out* (the original departure-phase gap) still
  always starts from the aircraft's live sim position regardless of what the pilot says
  -- see [Fuzzy ramp resolver](features/fuzzy-ramp-resolver.md).

## Where it's heading

The target architecture, once M4 (arrival) and its follow-ups land. Green is built today, amber
is in progress, and dashed is later work. Everything runs on the Windows PC next to X-Plane,
reading the sim's own data files; AWS only listens (Transcribe), speaks (Polly), and optionally
helps classify what the pilot said (Nova Lite). The deterministic engine decides every word ATC says.

[![Eventual xatc architecture: pilot on the left; on the Windows PC, X-Plane 12 and its data files feed the sim bridge, world data and weather, which feed the deterministic ATC engine with its phases, controllers, runway selector, clearance and SID selection, taxi router, arrival planner, conformance monitor and handoffs; phraseology and intent parsing sit beside it; the voice layer, radio panel and session services sit below; AWS Transcribe, Polly and Bedrock Nova Lite, SimBrief and the docs site are on the right, with later work (traffic, VFR, ICAO) dashed](assets/eventual-architecture.svg)](assets/eventual-architecture.svg)

*Click the diagram to open it full size.*

## Longer term

AI or multiplayer traffic (sequencing, traffic advisories), VFR support (pattern work,
flight following), and ICAO (non-US) phraseology are noted as later-stage ideas, well
past the current focus.
