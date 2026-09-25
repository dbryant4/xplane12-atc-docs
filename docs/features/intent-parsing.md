# Intent parsing & LLM modes

**Available now** -- the rules-based parser, an optional LLM fallback, and the options
screen are all real and wired together end to end.

## The rules-based parser

Every pilot transmission has to become a structured `Intent` before the [ATC
engine](controller-positions.md) can act on it. `xatc.phraseology.intent.parse_intent`
does this with plain keyword matching and regex-style extraction -- no model, no network
call, fully deterministic and unit tested.

```python
parse_intent(text, phase=Phase.TAXI_OUT, expected_callsign="November five four seven Golf Alpha")
```

Given *"Seattle Ground, request taxi at Alpha eleven, ready to copy,"* this returns
`IntentType.REQUEST_TAXI` at confidence 0.85, with the slot `{"location": "A11"}`
extracted from the phrase after "at". Given *"Seattle Departure, November five four
seven Golf Alpha, with you at two thousand five hundred climbing one zero thousand,"*
it returns `IntentType.CHECK_IN` with `{"altitude_ft": 2500, "climbing_to_ft": 10000}`.

Mismatches (an intent that's implausible for the current flight phase, or a spoken
callsign that doesn't match the one expected) only ever *reduce* confidence -- never
change the intent type or force it to zero.

### Number normalization

`xatc.phraseology.number_normalizer` turns spoken numbers into values, one fragment at
a time: "two five zero zero" → 2500 ft, "flight level three five zero" → 35,000 ft,
"four five two one" (squawk) → `"4521"` (rejects anything outside 0-7, since squawk
codes are octal), "one one niner point niner" (frequency) → 119,900 kHz.

## The LLM fallback (Nova Lite)

`xatc.intent_llm.NovaLiteIntentClassifier` calls Amazon Bedrock's Nova Lite model
(`amazon.nova-lite-v1:0`) through the Converse API, forced to a single tool call so its
output is always a validated `Intent`, never free text -- the same "never generates ATC
wording" boundary the [voice layer](voice.md) has (see the [core design
principle](../index.md#what-its-like-to-fly)). This only ever helps *classify* what the
pilot said; it never produces what ATC says back.

`xatc.intent_llm.IntentRouter` is what's actually injected into the engine, with three
runtime-switchable modes:

| Mode | Behavior |
|---|---|
| **Disabled** | Rules only. The classifier is never called. |
| **Backup** (`fallback`) | Rules run first; the classifier is only called when rules land on `UNKNOWN` or below a confidence threshold. |
| **Primary** | The classifier runs first; rules run instead whenever it fails, times out, or a per-session call cap is hit. |

A live classifier call blocks for up to about 1.5 seconds in Backup/Primary mode --
acceptable at this project's current traffic scale (one aircraft), not something that's
been made asynchronous.

## The options screen

The gear icon in the [radio panel](radio-panel.md) has three radio buttons -- Disabled,
Backup, Primary -- matching the modes above, applying immediately, plus an LLM status
line (call count, average response time, last error). This is real, live-switchable
state now: selecting a mode calls `IntentRouter.set_mode`, persists it to a small local
settings file, and every connected panel sees the update via the same broadcast
[sim_status](radio-panel.md) and other session state already uses.

`xatc run --intent-mode {disabled,fallback,primary}` sets it for one run without
changing what's persisted; with no flag, the last-used mode is remembered, defaulting to
Backup when `--voice` is on and Disabled otherwise.

## Configuration

```bash
xatc run --voice --intent-mode fallback   # or disabled / primary
```

Nova Lite calls need `bedrock:InvokeModel`/`InvokeModelWithResponseStream` on top of the
IAM permissions [Voice](voice.md) already needs -- see the repository's `infra/` for the
managed policy.

## Limitations

- A live classifier call can add up to ~1.5s of latency in Backup/Primary mode; the
  engine call is synchronous, not asynchronous.
- Several `IntentType` values (`REQUEST_PUSHBACK`, `REQUEST_ALTITUDE`,
  `REQUEST_DIRECT`, `REQUEST_APPROACH`) exist in the shared contract but nothing
  produces them yet, rules or LLM.
- The engine doesn't yet pass which controller position a transmission arrived on into
  the classifier, even though both the router and the classifier already accept it --
  a small follow-up on the engine side, not required for this to work today.
