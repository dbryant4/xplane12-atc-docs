# Voice (Transcribe, Polly, PTT)

**Available now.**

## What it does

Push-to-talk voice, end to end: hold PTT and speak, AWS Transcribe turns it into text,
the [ATC engine](controller-positions.md) decides the reply, and Amazon Polly speaks it
back through the [VHF radio effect](radio-fx.md). No LLM is involved anywhere in this
path -- see the [core design principle](../index.md#what-its-like-to-fly).

This is `xatc.voice.session.RadioVoiceSession`, built around two small, independently
swappable backends (`SpeechToText`, `TextToSpeech`) rather than one monolithic voice
provider, plus the radio behavior that sits above both:

- **Half-duplex.** Keying up cuts off whatever ATC audio is currently playing -- not
  just muting new playback, actually stopping it -- the same as a real simplex VHF
  radio. Nothing new plays while you're transmitting; it queues instead.
- **Priority.** Queued replies play in `AtcTransmission.priority` order (routine, then
  handoffs, readback corrections, and urgent calls like "hold position!" jump the
  queue), FIFO within the same priority.
- **The ATIS loop.** The engine only emits a new ATIS broadcast when the information
  letter changes, not every tick -- so the session itself remembers the latest broadcast
  per frequency and replays it on a loop while that frequency is being listened to (COM1
  or COM2's *active* frequency; see [Controller positions](controller-positions.md)).
  Tuning away cuts the currently-playing broadcast off within one audio block instead of
  letting it finish; a letter change while already tuned in switches to the new broadcast
  at the next loop boundary, not mid-utterance. Where a fresh tune-in joins the loop depends on
  the `voice.atis_start` setting (see [Settings](../settings.md)): **broadcast** (the
  default) joins partway through, like a real ATIS you're just now receiving; **beginning**
  always starts at "...information Alpha..." instead.
- **Untuned frequencies aren't heard.** A reply only plays if it's on a frequency either
  radio is actively listening to -- a controller's own reminders or handoff chatter meant
  for a frequency you've since retuned away from stays silent, the same as a real radio.
- **Voice per position type**, for a bit of realism -- with `voice.controller_voices` set
  to **varied** (the default), every controller position (Ground, Tower, Departure,
  Center, Approach) gets its own Amazon Polly neural voice, assigned deterministically so
  the same controller always sounds the same and a handoff always changes voice; **single**
  uses one voice for every position. ATIS always gets its own dedicated voice either way.
  See [Settings](../settings.md).

## How a transmission actually flows

```text
PTT down  ->  mic audio streamed to Transcribe, 16 kHz mono PCM, live
PTT up    ->  final transcript  ->  engine.on_pilot_transmission(tuned_freq, text)
          ->  each AtcTransmission reply synthesized by Polly (neural, 16 kHz PCM)
          ->  run through RadioFx (key_up / process / unkey, one instance per reply)
          ->  played
```

`AtcTransmission.text` is always spoken **verbatim** -- Polly reads exactly what the
engine wrote by construction, so there's no risk of a voice layer paraphrasing a
clearance (the same risk an earlier Nova 2 Sonic speech-to-speech design carried, and
the reason this project moved away from it -- see ADR 0004 in the repository).

## Voice is always on

There's no toggle (ADR 0012) -- not a setting, not a flag, not a per-run choice. `uv
sync` installs everything voice needs as ordinary dependencies (no more separate `voice`
extra to remember), and every real run tries to start voice. `xatc run --voice` still
parses, but only as a documented no-op kept for one release so an old script or shortcut
that still passes it doesn't break -- it does nothing.

`botocore[crt]`, which AWS CLI v2's `aws login` credentials need on Windows (see [Getting
Started](../getting-started.md) step 3), comes along the same way -- nothing extra to
install or configure.

## When voice can't start

Bad or expired AWS credentials, no working microphone, or a Transcribe/Polly error never
block or crash startup -- xatc always starts, in whatever state voice ends up in:

- The radio panel gets a `{"type": "voice_status", "available": bool, "detail": "..."}`
  broadcast the moment voice's state is known (and again on every change), naming exactly
  what's wrong (e.g. *"AWS credentials not signed in -- check Settings -> Voice"*) and
  what to do about it.
- **Push-to-talk is disabled with that reason** -- the on-screen button, holding Space,
  and a hardware yoke/joystick button all refuse the same way, showing the detail as a
  tooltip or a plain status line instead of erroring. There's no separate "voice off"
  state to design around: unavailable is unavailable, however you tried to key up.
- **Type-to-transmit keeps working regardless** -- it's the panel's own input, never
  gated on voice. This is how you keep flying while voice is down, not a mode you have
  to switch into.
- **It retries automatically**: saving anything on the Voice tab, or fixing AWS
  credentials externally (`aws login`) and coming back, triggers a fresh attempt with
  whatever's currently configured. There's no *"Retry voice"* button in the panel yet --
  saving Voice settings is the way to force a retry right now.
- **The LLM helpers sit out too, and come back together.** The readback judge,
  conversational ATC, and Nova Lite intent classification all need the same AWS access
  voice does, so all three switch off automatically the moment voice becomes unavailable
  (falling back to rules-only intent parsing and the plain rules-based readback checker)
  and switch back on together once voice recovers -- restoring whatever intent mode you
  actually had configured, not just flipping back on unconditionally. An explicit
  **Disabled** intent mode is left alone either way: it stays off before, during and
  after a voice outage.

This is the *only* path now -- there's no separate "voice deliberately off" branch to
fall into. A missing dependency, specifically, should never actually happen after a
normal `uv sync` (they're ordinary dependencies now), but the same check and the same
fallback still cover a broken or partial install rather than crashing on it.

## Configuration

A few flags still matter, independent of the always-on change above:

| Flag | Effect |
|---|---|
| `--vocabulary NAME` | Transcribe custom vocabulary to use (default `xatc-aviation-en-US`, provisioned by `infra/` -- see [Getting Started](../getting-started.md)) |
| `--no-vocabulary` | Skip the custom vocabulary entirely |
| `--aws-region REGION` | Region for Transcribe/Polly (default `us-east-1`) |

Push-to-talk itself is bound in the [radio panel](radio-panel.md): the on-screen PTT
button, or holding **Space** while the page has focus (ignored while typing in a text
field, so Space still types spaces there) -- see [Push-to-talk from
hardware](joystick-ptt.md) for a real yoke or joystick button instead.

## The Nova 2 Sonic spike

An earlier spike (`xatc.voice.spike_nova`) tried Amazon Nova 2 Sonic as a single
bidirectional speech-to-speech model instead of separate STT/TTS calls. It's kept in the
repository for reference but is **not** on the current path -- ADR 0004 replaced it with
Transcribe + Polly specifically because the deterministic engine only needs exact speech
recognition and exact-text speech synthesis, and Polly can't paraphrase a clearance the
way a speech-to-speech model theoretically could.

## Limitations

- Requires a live AWS connection for both directions -- there's no offline voice path.
  Without one, voice is simply unavailable (see above); type-to-transmit on the [radio
  panel](radio-panel.md) works regardless.
- No *"Retry voice"* control in the panel yet -- saving the Voice tab (even with nothing
  actually changed) is the only way to force a retry right now.
- The custom vocabulary must be deployed and its name must match what `xatc run` is
  told, or transcription runs without domain-specific hints.
- No sidetone (hearing your own transmitted audio played back) is implemented.
- Signal-strength scaling by distance/altitude to the controlling facility (a scratchier
  center sector than a nearby tower) is not implemented -- every reply uses the same
  `RadioFx` preset regardless of range.
