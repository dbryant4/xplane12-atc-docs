# VHF radio effect

**Available now.**

## What it does

Every piece of ATC audio -- whether synthesized by [Polly](voice.md) or (historically)
Nova -- is run through `xatc.voice.radio_fx.RadioFx` before it reaches the speaker, so it
sounds like it came over a real VHF radio instead of a clean text-to-speech voice.

`RadioFx` is a streaming, stateful DSP chain: one instance per transmission, fed chunk
by chunk as audio is synthesized (`key_up()` once, `process(chunk)` per chunk,
`unkey()` once), so it's causal and can't click or restart mid-utterance the way a
whole-buffer filter would. `apply_radio_fx()` is a convenience wrapper for offline,
whole-buffer rendering (`key_up` + one `process` + `unkey`).

The chain, in order:

1. **Band-pass filter** -- a 300-3,000 Hz, 4th-order Butterworth band-pass. This alone
   is most of what makes a voice sound like it's coming over an airband radio instead of
   a phone call.
2. **Compression and soft clipping** -- heavy gain (`drive`) followed by `tanh` soft
   saturation, copying the loud, flat, slightly overdriven sound of AM modulation.
3. **Carrier hiss** -- filtered white noise mixed continuously under the voice, with a
   slow 2-6 Hz amplitude flutter, running under the whole transmission (not restarted
   per chunk).
4. **Squelch clicks and key tail** -- a short noise burst at key-up, open-carrier hiss
   padding before and after speech, and another burst (the squelch "tail") at unkey.

## Configuration

Three presets, passed as `radio_fx_preset` when constructing a voice session:

| Preset | Effect |
|---|---|
| `clean` | All effect parameters at zero -- band-pass only has no practical effect since nothing else colors the signal; useful for testing |
| `realistic` (default) | Moderate drive, hiss, flutter, and squelch clicks |
| `busy-day` | More of all of the above -- a noisier band |

Each preset is a `RadioFxParams` dataclass (band edges, filter order, drive, hiss level,
flutter depth/rate, squelch click level, key-tail duration) -- all independently
tunable if a new preset is ever needed.

## Verification

`tests/test_radio_fx.py` checks the band-pass actually attenuates energy outside
300-3,000 Hz on a synthetic sweep, and that `RadioFx` output changes when given
different input rather than being a no-op. It's skipped outside the `voice` extra
(needs `numpy`/`scipy`), same as everything else in `xatc.voice`.

## Limitations

- No signal-strength scaling by distance or line-of-sight -- every transmission uses the
  same preset regardless of how far the controlling facility is.
- No pilot sidetone (hearing your own transmitted audio).
- Two COMs playing simultaneously (e.g. ATIS under a live controller) is not mixed in
  the audio chain itself -- `RadioFx` processes one transmission at a time, and the
  [voice session](voice.md)'s half-duplex/priority queue serializes playback rather than
  layering it.
