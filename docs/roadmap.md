# Roadmap

## Where things stand

xatc flies a **full IFR flight gate to gate**: from the ATIS and the clearance at a gate,
through pushback, taxi, takeoff, departure, Center, the arrival, the approach and the
landing, to taxi-in and parking. It all runs by voice, at any airport X-Plane's scenery
covers, with a deterministic engine deciding every word ATC says.

| Milestone | Status | What it covers |
|---|---|---|
| **M0: spikes** | ✅ done | X-Plane Web API, apt.dat and atc.dat parsing, sim weather, the voice round trip |
| **M1: ground ops** | ✅ done | [ATIS](features/atis-weather.md), [IFR clearance](features/ifr-clearance.md), [taxi with hold-shorts](features/taxi-routing.md), the [radio panel](features/radio-panel.md), wrong-frequency silence |
| **M2: voice** | ✅ done | [Transcribe + Polly](features/voice.md), push-to-talk, the [VHF radio effect](features/radio-fx.md) |
| **M3: departure** | ✅ done | [Tower takeoff clearance](features/tower-clearance.md); [Tower → Departure → Center](features/departure-center.md); a CIFP-assigned [SID](features/sid-departure-procedures.md); [readback checking](features/readback-checking.md); the [conformance monitor](features/conformance-monitor.md) |
| **M4: arrival** | ✅ done | [Descent via a STAR, approach clearance, landing clearance, taxi-in, go-around and parking](features/arrival.md) |
| **M5: realism** | ✅ done | ATIS-letter checks, en-route pilot requests, emergencies and special squawks, pushback (details below) |
| **M6: VFR** | ✅ done | Pattern work (M6-1), flight following (M6-2), and Class B/C/D airspace entry (M6-3), details below |
| **M7: traffic awareness** | 🔶 in progress | Advisory logic built and tested (M7-2) -- not live until the X-Plane traffic feed lands; sequencing (M7-3) next |

### M5: the most common "real ATC" interactions
- **ATIS-letter check.** Report an old letter on first contact with Clearance, Ground or
  Approach and ATC answers "information Bravo is current, altimeter …". Report none and
  it asks you to "advise you have information Alpha" (7110.65 2-9-3).
- **Pilot requests en route.**
  - "request direct &lt;fix&gt;" gets "cleared direct …", or "unable" if the fix isn't
    on your route.
  - "request higher / lower / flight level &lt;n&gt;" gets a new altitude.
  - Weather deviations are approved with "advise when able to proceed direct …".
  - "unable" takes back the last instruction and restates the one before it.
- **Emergencies.** "Mayday" or "pan-pan" (or squawking 7700, transponder on or in ALT)
  gets "say souls on board and fuel remaining". 7600 (lost comms) gets "if you hear this
  transmission, ident". 7500 gets one discreet verification. "Cancel mayday" ends it and
  restores conformance callouts, which otherwise go quiet during an emergency -- still
  logged for the [debrief](features/debrief.md#the-markdown-summary)'s own Radio events
  section.
- **Pushback.** "request pushback" gets "push back approved, tail &lt;direction&gt;". The
  direction comes from the taxilane behind your stand and which way it leads to the
  departure runway. An IFR flight needs its clearance first -- ask before you have it
  and Ground answers "clearance on &lt;frequency&gt;" instead.

### M6-1: VFR pattern work at a towered airport
- **Set VFR** on the Settings Flight tab with the destination the same as departure (ADR
  0008), and Ground taxis you out with no IFR clearance at all.
- **Closed traffic.** "cleared for takeoff, make right closed traffic" -- the side comes
  from the airport's own `1101` pattern data, left by default.
- **The circuit.** Climb through 40% of the way to pattern altitude (400 ft for a
  piston, 600 for a turbine or jet) and Tower says "report midfield downwind"; call it
  and get "cleared for the option" (touch-and-go/stop-and-go/option) or "cleared to
  land" (full stop, the default) -- "number one" either way, since it's always just you.
- **Pattern altitude is by aircraft category** (F8): 1,000 ft AGL for a piston, 1,500
  for a turbine or jet, by ICAO type designator.
- **Pattern-altitude and leaving-the-pattern conformance**, plus landing-without-
  clearance reused for every circuit -- see [VFR pattern work](features/vfr-pattern.md).

### M6-2: VFR flight following
- **Leaving Tower's airspace.** Climbing through 1,000 ft AGL after a VFR takeoff to
  another airport, Tower says "frequency change approved" -- no handoff, it's yours from
  there.
- **Requesting it.** "request flight following to &lt;airport&gt;" (or "VFR advisories")
  to Departure, Approach or Center gets a squawk, then "radar contact …" once your
  transponder actually shows it, on or in ALT.
- **Handoffs**, Departure/Approach → Center → destination Approach, use the same
  machinery (and the same "are you with me?" reminders) as an IFR flight's.
- **Conformance only while following.** With no IFR clearance, nothing is checked at all
  until radar contact -- then altitude, heading, speed and squawk are watched exactly
  like an IFR flight's.
- **Termination**, within 10 nm of the destination: "radar service terminated, squawk
  VFR, frequency change approved." See [VFR flight
  following](features/vfr-flight-following.md).

### M6-3: VFR Class B/C/D airspace entry
- **Class B needs a request.** "request Bravo clearance" gets "cleared into the Class
  Bravo airspace, maintain VFR at or below &lt;altitude&gt;"; entering uncleared gets an
  escalating callout.
- **Class C and D just need contact.** Ordinary two-way radio contact (the controller
  using your callsign) satisfies it -- no request needed; entering before that gets an
  escalating callout naming the airspace.
- **Class B altitude limit** (F10): climbing above your cleared "at or below" altitude
  gets its own escalating callout. See [VFR Class B/C/D airspace
  entry](features/vfr-airspace-entry.md).

### M7: traffic awareness
- **M7-1 (ADR 0010)** laid the groundwork: a `TrafficTarget` snapshot type and the
  geometry `atc/traffic.py` needs.
- **M7-2** wired a full advisory pipeline into the engine and phraseology: "traffic,
  twelve o'clock, five miles, opposite direction, Boeing seven thirty seven, altitude
  indicates same altitude," from whoever has you airborne, with backoff and "traffic in
  sight" handling. **Not live yet** -- there's no X-Plane traffic feed wired up today, so
  this only runs against test data. See [Traffic advisories](features/traffic-advisories.md).
- **F10** also gave KBFI's Class D real Laminar Research atc.dat data in its test
  coverage, replacing a synthetic placeholder.
- **A real bug, fixed**: an `apt.dat` file that spells a runway inconsistently between
  its own row and its hold-short rows (e.g. KLAX's "6R" vs. "06R") could falsely flag a
  clean, correctly-flown runway crossing as an incursion, or name the wrong runway end in
  a taxi instruction or an incursion event -- confirmed at real airports (KLAX, KJFK) and
  fixed everywhere runway ids get looked up. See [Conformance
  monitor](features/conformance-monitor.md#ground-conformance) and [Taxi routing &
  hold-shorts](features/taxi-routing.md).

### Also built along the way
- **[Any airport](features/any-airport-data.md).** Airport, procedure and airspace data
  comes straight from your X-Plane install, including Custom Scenery priority, X-Plane's
  own CIFP files and fix coordinates. It was checked against 15 real airports, which
  found and fixed three real bugs.
- **Center sector and ARTCC handoffs**, and **"are you with me?" reminders** after any
  handoff you don't check in from.
- **Settings page (ADR 0007).** Run `xatc` with no arguments and configure everything
  from the panel: the flight plan (manual or [SimBrief](features/simbrief-import.md)),
  the connection, voice, ATC options and advanced settings. Command-line flags remain as
  per-run overrides.
- **[Push-to-talk from hardware](features/joystick-ptt.md)** -- straight from X-Plane's
  own joystick datarefs by default (Windows and macOS), or a joystick/yoke library
  directly (Windows only) -- the [post-flight debrief](features/debrief.md), and
  [distance-based signal strength](features/radio-fx.md#signal-strength-by-distance).
- **An FAA JO 7110.65 phraseology audit.** A golden test suite cites the paragraph each
  transmission follows, with pronunciation overrides for local fix names ("Iceberg",
  "King Dome").
- **Windows setup**: `xatc doctor`, `xatc smoke --live`, `setup-windows.ps1` and a
  double-click `xatc-run.cmd`. See [Getting Started](getting-started.md#running-on-windows).

See [Features](features/index.md) for the per-feature "available now" breakdown.

## What's next

1. **The live X-Plane traffic feed**: `SimBridge.traffic()` and the `xatc run --live`
   wiring that feeds it into the engine, once the owner confirms the TCAS datarefs live
   (ADR 0010) -- this is what actually turns on [traffic
   advisories](features/traffic-advisories.md).
2. **M7-3: sequencing behind traffic.** Builds on M7-2's traffic snapshot: "number two,
   follow the Boeing seven thirty seven on a five mile final, report it in sight," with a
   wake-turbulence caution behind a heavy.
3. **First live flights on the Windows PC**: a real KSEA departure recording to replace
   the synthetic scenario tests, and confirming joystick PTT and the new altitude
   datarefs on real hardware.

## Where it's heading

The target architecture. Green is built today, amber is next, and dashed is later
work. Everything runs on the Windows PC next to X-Plane, reading the sim's own data
files. AWS only listens (Transcribe), speaks (Polly) and optionally helps classify what
the pilot said (Nova Lite). The deterministic engine decides every word ATC says.

[![xatc architecture: pilot on the left; on the Windows PC, X-Plane 12 and its data files feed the sim bridge, world data and weather, which feed the deterministic ATC engine with its phases (parked through pushback, taxi, departure, enroute, descent, approach, landing, taxi-in and parked again), controllers, runway selector, clearance and SID selection, taxi router, arrival planner, conformance monitor and handoffs; phraseology and intent parsing sit beside it; the voice layer, radio panel with its Settings page, and session services sit below; AWS Transcribe, Polly and Bedrock Nova Lite, SimBrief and the docs site are on the right; VFR is next, and traffic, ICAO phraseology and an installer are later](assets/eventual-architecture.svg)](assets/eventual-architecture.svg)

*Click the diagram to open it full size.*

## Longer term

- **AI or multiplayer traffic**, once there's a live feed to sequence against (M7-3 and
  beyond).
- **ICAO (non-US) phraseology.**
- **A one-click Windows installer.**
- **Per-facility altimeter settings and airspace speed limits** (91.117(b) and (c)).
