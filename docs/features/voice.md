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
  per frequency and replays it every couple of seconds while that frequency is being
  listened to (COM1 or COM2's *active* frequency; see
  [Controller positions](controller-positions.md)). A newer broadcast for the same
  frequency replaces one still waiting to play; an identical one already playing is left
  alone rather than restarted.
- **Voice per position type**, for a bit of realism -- Ground and Tower get one Polly
  voice, Clearance and Departure another, ATIS a third, all overridable.

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

## Configuration

`xatc run --voice` turns voice on. A few flags matter:

| Flag | Effect |
|---|---|
| `--vocabulary NAME` | Transcribe custom vocabulary to use (default `xatc-aviation-en-US`, provisioned by `infra/` -- see [Getting Started](../getting-started.md)) |
| `--no-vocabulary` | Skip the custom vocabulary entirely |
| `--aws-region REGION` | Region for Transcribe/Polly (default `us-east-1`) |

Push-to-talk itself is bound in the [radio panel](radio-panel.md): the on-screen PTT
button, or holding **Space** while the page has focus (ignored while typing in a text
field, so Space still types spaces there).

The `voice` extra pulls in `botocore[crt]`, which AWS CLI v2's `aws login` credentials
need on Windows (see [Getting Started](../getting-started.md) step 3) -- installing the
voice extra is enough, nothing extra to configure.

## The Nova 2 Sonic spike

An earlier spike (`xatc.voice.spike_nova`) tried Amazon Nova 2 Sonic as a single
bidirectional speech-to-speech model instead of separate STT/TTS calls. It's kept in the
repository for reference but is **not** on the current path -- ADR 0004 replaced it with
Transcribe + Polly specifically because the deterministic engine only needs exact speech
recognition and exact-text speech synthesis, and Polly can't paraphrase a clearance the
way a speech-to-speech model theoretically could.

## Limitations

- Requires a live AWS connection for both directions -- there's no offline voice path
  (use [text mode](radio-panel.md#text-mode) instead when developing without AWS).
- The custom vocabulary must be deployed and its name must match what `xatc run` is
  told, or transcription runs without domain-specific hints.
- No sidetone (hearing your own transmitted audio played back) is implemented.
- Signal-strength scaling by distance/altitude to the controlling facility (a scratchier
  center sector than a nearby tower) is not implemented -- every reply uses the same
  `RadioFx` preset regardless of range.
