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
- The ground rules for a [conformance monitor](features/conformance-monitor.md) --
  taxiing without clearance, straying off the assigned route, runway incursions, and
  takeoff without clearance, each with a real escalation ladder and a strictness
  setting, verified against a real recorded flight with zero false positives. Not yet
  connected to the engine, so none of it reaches a pilot today.
- A [fuzzy ramp/parking resolver](features/fuzzy-ramp-resolver.md) -- understands a
  spoken ramp or gate reference, tolerant of ASR mistakes, weighted by real distance
  from the aircraft. Also not yet connected to anything: [taxi
  routing](features/taxi-routing.md) still always starts from the aircraft's live sim
  position regardless.

See [Features](features/index.md) for the detailed, per-feature "available now" vs.
"planned" breakdown.

## What's next

Roughly in the order the project is tackling it:

- **Wire the conformance monitor into the engine.** The ground rules, escalation
  ladder, and strictness levels are already built and well-tested (see [Conformance
  monitor](features/conformance-monitor.md)) -- what's left is calling it from
  `on_tick`, routing its events through phraseology for real spoken wording, and
  deciding a few open design questions (an explicit runway-crossing-clearance field, an
  IMC/ILS-hold flag, exactly how severity maps to priority).
- **Wire the fuzzy ramp resolver into taxi routing.** Also already built and tested
  (see [Fuzzy ramp resolver](features/fuzzy-ramp-resolver.md)) -- what's left is having
  the engine actually pass a pilot's spoken location into it instead of always using the
  sim position outright.
- **Approach and landing.** STAR/vectors, an approach clearance, a landing clearance,
  and the handoff back to Ground once you're clear of the runway. None of this exists
  yet -- the engine currently has no logic past the departure phase.
- **Readback correction.** Actually checking a readback against what was issued,
  instead of always accepting it.
- **CIFP-based SID selection.** Clearances currently only echo a SID from your filed
  flight plan; there's no procedure data to let ATC actually assign one.
- **SimBrief flight-plan import**, instead of the current CLI-flag-only flight plan.
- **Any-airport generalization.** The engine, runway selector, and taxi router are all
  airport-agnostic in design, but magnetic variation and a couple of other constants are
  currently hardcoded for KSEA specifically.
- **Distance-based radio realism** -- signal strength and noise scaling with distance
  and line-of-sight to the controlling facility, so a distant Center sector sounds
  scratchier than Tower on the ramp.

## Longer term

AI or multiplayer traffic (sequencing, traffic advisories), VFR support (pattern work,
flight following), and ICAO (non-US) phraseology are noted as later-stage ideas, well
past the current focus.
