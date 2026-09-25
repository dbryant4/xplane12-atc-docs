# Radio panel

**Available now.**

![The xatc radio panel mid-session at KSEA](../assets/radio-panel.png)

*The radio panel after a clearance and taxi exchange at KSEA: COM2 is transmitting on Seattle Ground, the Status section shows what's been issued (squawk, runway 16L, taxi via B, hold short of 16L), and the transcript shows each pilot call and ATC reply, including the readback checks.*

## What it does

A local web app (FastAPI + one WebSocket) serves a single, dependency-free HTML/JS
page that behaves like a real COM radio stack, open in a browser on any device on your
network:

- **COM1 and COM2** -- active and standby frequencies, a flip-flop button, a tuning
  knob (drag, scroll, or a numeric keypad, 25 kHz or 8.33 kHz steps), and a TX light
  that's green when that radio is selected to transmit and red once a push-to-talk mic
  stream is actually confirmed open (not just "the button is pressed").
- **Two-way sync with X-Plane.** Tuning the panel writes the COM frequency to the sim;
  turning the knobs in the cockpit updates the panel. Either one can drive.
- **Status section** -- the current flight phase and whatever's actually been issued on
  the current clearance: squawk, runway, assigned or expected altitude, departure
  frequency, taxi route, and hold-shorts. Only fields that are actually set show up, so
  it starts almost empty on the ramp and fills in as ATC issues things.
- **Frequency directory** -- nearby controller positions, sorted by relevance to the
  current phase. Click one to load it into a COM's standby. Whichever position you've
  just been [handed off to](controller-positions.md#handoffs) is highlighted, with a
  one-click "Load & swap" that tunes and switches the TX radio to it directly, instead
  of loading to standby and flip-flopping separately.
- **Transcript** -- every transmission, tagged by frequency and station, plus a
  type-to-transmit box for text mode.
- **Push-to-talk** -- an on-screen button, or holding Space while the page has focus
  (ignored while typing in a text field). See [Voice](voice.md).
- **Options screen** -- a gear icon opens a modal for session settings. Currently:
  "ATC understanding" (see [Intent parsing & LLM modes](intent-parsing.md) -- the UI is
  real, nothing's wired behind it yet) and an LLM status line, structured so future
  settings (radio effect preset, voices) are just another section.
- **Sim connection indicator** -- shows live X-Plane version and connection state, or
  which replay file is playing and whether it's still moving or holding at the end of
  the recording.

## Text mode

Everything works with no voice and no AWS account: type a transmission into the box
instead of speaking it, and the panel's the primary UI. This is also how the project
develops and tests without needing a live sim.

## Two-way COM sync

All frequency changes go through one interface the engine's sim bridge implements,
whether that's a live X-Plane Web API connection or a recorded/replayed flight -- the
panel never talks to a specific bridge implementation directly, so it behaves
identically either way.

## Configuration

```bash
xatc run --host 0.0.0.0 --port 8000 ...   # bind address/port
xatc panel --replay <file>                # a standalone dev/demo server, loops the replay
```

Run `xatc run --help` for the full set of flags (voice, weather fixtures, flight plan,
live vs. replay).

## Limitations

- The header shows the aircraft's raw tail number, not the spoken callsign ATC actually
  uses -- and there's no edit override if it's wrong.
- No audio volume/RX-monitor-toggle controls beyond what half-duplex playback already
  does (see [Voice](voice.md)).
- No post-flight debrief view.
