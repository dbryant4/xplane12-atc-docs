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
  every transmission and conformance call logged to a session file, with a Markdown
  summary (timeline, deviations by severity) written automatically or regenerated on
  demand.

This closes out the departure-phase milestone in full: ground ops, a full departure and
enroute handoff chain, a real CIFP-assigned SID, and a checked readback, all the way
through the initial enroute climb. Arrivals are next -- see below.

See [Features](features/index.md) for the detailed, per-feature "available now" vs.
"planned" breakdown.

## What's next

Roughly in the order the project is tackling it:

- **Approach and landing.** STAR/vectors, an approach clearance, a landing clearance,
  and the handoff back to Ground once you're clear of the runway. Groundwork exists --
  `xatc.atc.arrival_planner` already picks a STAR and an approach type/procedure from
  CIFP data and the current weather -- but nothing in the engine calls it yet; this is
  in progress, not available.
- **Wire the fuzzy ramp resolver into taxi routing.** Already built and tested (see
  [Fuzzy ramp resolver](features/fuzzy-ramp-resolver.md)) -- what's left is having the
  engine actually pass a pilot's spoken location into it instead of always using the sim
  position outright.
- **Relaxed-mode readback gating.** A readback problem restated without holding up the
  flight over it, under the relaxed conformance-strictness setting -- designed, not yet
  built (see [Readback checking](features/readback-checking.md)).
- **A debrief readback section**, once the summary can point out exactly where a
  readback was wrong or missing, not just conformance events.

## Longer term

AI or multiplayer traffic (sequencing, traffic advisories), VFR support (pattern work,
flight following), and ICAO (non-US) phraseology are noted as later-stage ideas, well
past the current focus.
