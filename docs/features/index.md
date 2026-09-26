# Features

Every page below is written from the code on `main`, not from the original design
plan, and marked by what actually runs today.

| Feature | Status |
|---|---|
| [Radio panel](radio-panel.md) | Available now |
| [Controller positions & frequencies](controller-positions.md) | Available now |
| [ATIS & weather](atis-weather.md) | Available now |
| [Runway selection](runway-selection.md) | Available now |
| [IFR clearance (CRAFT)](ifr-clearance.md) | Available now |
| [SID & departure procedures](sid-departure-procedures.md) | Available now (KSEA, KPDX) |
| [Readback checking](readback-checking.md) | Available now |
| [Taxi routing & hold-shorts](taxi-routing.md) | Available now |
| [Tower takeoff clearance](tower-clearance.md) | Available now (line-up-and-wait not wired up) |
| [Voice (Transcribe, Polly, PTT)](voice.md) | Available now |
| [VHF radio effect](radio-fx.md) | Available now (with distance-based signal strength) |
| [Intent parsing & LLM modes](intent-parsing.md) | Available now (rules parser, Nova Lite fallback, and the Settings page's ATC tab) |
| [Departure & Center](departure-center.md) | Available now, including Center-to-Center ARTCC handoffs |
| [Arrival](arrival.md) | Available now, gate to gate, including go-around |
| [Conformance monitor](conformance-monitor.md) | Available now -- ground, airborne, landing, pattern and airspace rules, all wired into the engine |
| [Fuzzy ramp resolver](fuzzy-ramp-resolver.md) | Available now for taxi-in (M4-3); not yet wired into taxi-out |
| [Any-airport data loading](any-airport-data.md) | Available now |
| [SimBrief import](simbrief-import.md) | Available now |
| [Post-flight debrief](debrief.md) | Available now |
| [Joystick/yoke push-to-talk](joystick-ptt.md) | Available now (Windows only; refused on macOS) |
| [ATIS letter check](atis-letter-check.md) | Available now |
| [En-route pilot requests](enroute-requests.md) | Available now (direct-to, altitude, deviation, unable) |
| [Emergencies and special squawks](emergencies.md) | Available now (7500/7600/7700) |
| [Pushback](pushback.md) | Available now |
| [VFR pattern work](vfr-pattern.md) | Available now, at a towered airport (M6-1) |
| [VFR flight following](vfr-flight-following.md) | Available now (M6-2) |
| [VFR Class B/C/D airspace entry](vfr-airspace-entry.md) | Available now (M6-3, F10) |
| [Traffic advisories](traffic-advisories.md) | Built and tested (M7-2) -- not live, no X-Plane traffic feed wired up yet |

See the [Roadmap](../roadmap.md) for what's coming next and in what order.
