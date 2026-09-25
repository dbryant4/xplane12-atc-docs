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

See [Features](features/index.md) for the detailed, per-feature "available now" vs.
"planned" breakdown.

## What's next

Roughly in the order the project is tackling it:

- **Wire the fuzzy ramp resolver into taxi routing.** Already built and tested (see
  [Fuzzy ramp resolver](features/fuzzy-ramp-resolver.md)) -- what's left is having the
  engine actually pass a pilot's spoken location into it instead of always using the sim
  position outright.
- **Approach and landing.** STAR/vectors, an approach clearance, a landing clearance,
  and the handoff back to Ground once you're clear of the runway. None of this exists
  yet -- the engine currently has no logic past the departure phase.
- **Readback correction.** Actually checking a readback against what was issued,
  instead of always accepting it.
- **CIFP-based SID selection.** Clearances currently only echo a SID from your filed
  flight plan; there's no procedure data to let ATC actually assign one.
- **SimBrief flight-plan import**, instead of the current CLI-flag-only flight plan.
- **Distance-based radio realism** -- signal strength and noise scaling with distance
  and line-of-sight to the controlling facility, so a distant Center sector sounds
  scratchier than Tower on the ramp.

## Longer term

AI or multiplayer traffic (sequencing, traffic advisories), VFR support (pattern work,
flight following), and ICAO (non-US) phraseology are noted as later-stage ideas, well
past the current focus.
