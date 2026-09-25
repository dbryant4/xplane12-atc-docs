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
| **M6: VFR** | 🔶 M6-1 done | Pattern work at a towered airport (M6-1, details below); VFR flight following next (M6-2) |

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
- **The circuit.** Climb through 400 ft and Tower says "report midfield downwind"; call
  it and get "cleared for the option" (touch-and-go/stop-and-go/option) or "cleared to
  land" (full stop, the default) -- "number one" either way, since it's always just you.
- **Pattern-altitude and leaving-the-pattern conformance**, plus landing-without-
  clearance reused for every circuit -- see [VFR pattern work](features/vfr-pattern.md).

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
- **[Joystick / yoke push-to-talk](features/joystick-ptt.md)**, the
  [post-flight debrief](features/debrief.md), and
  [distance-based signal strength](features/radio-fx.md#signal-strength-by-distance).
- **An FAA JO 7110.65 phraseology audit.** A golden test suite cites the paragraph each
  transmission follows, with pronunciation overrides for local fix names ("Iceberg",
  "King Dome").
- **Windows setup**: `xatc doctor`, `xatc smoke --live`, `setup-windows.ps1` and a
  double-click `xatc-run.cmd`. See [Getting Started](getting-started.md#running-on-windows).

See [Features](features/index.md) for the per-feature "available now" breakdown.

## What's next

1. **M6-2: VFR flight following.** "request flight following to &lt;airport&gt;" gets a
   squawk and radar contact, then handoffs, then "radar service terminated, squawk VFR"
   near the destination.
2. **First live flights on the Windows PC**: a real KSEA departure recording to replace
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

- **AI or multiplayer traffic:** sequencing and traffic advisories.
- **ICAO (non-US) phraseology.**
- **A one-click Windows installer.**
- **Push-to-talk read straight from X-Plane's joystick bindings.**
- **Per-facility altimeter settings and airspace speed limits** (91.117(b) and (c)).
