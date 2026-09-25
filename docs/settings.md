# Settings reference

xatc keeps everything you configure in one file, edited from the **Settings** page of the radio
panel (the gear icon, top right). This page lists every setting: what it does, its default, when
a change takes effect, and the command-line flag that can override it for a single run.

## How settings work

- **Run `xatc` with no arguments** (or double-click `scripts\xatc-run.cmd` on Windows). xatc starts
  from your saved settings and opens the panel in your browser. There's nothing to type.
- **Where they're saved:** one `settings.json` file.

  | OS | Path |
  |---|---|
  | Windows | `%LOCALAPPDATA%\xatc\settings.json` |
  | macOS | `~/Library/Application Support/xatc/settings.json` |
  | Linux | `~/.config/xatc/settings.json` |

  The Settings page shows the exact path with an *Open folder* link. The file is versioned
  (`"schema_version": 1`), so older files are migrated automatically. If the file is unreadable or
  invalid, xatc starts with defaults and logs a warning; it never refuses to start.
- **Saving:** each tab has its own **Save**. The server validates every field. A bad value shows an
  error next to that field, and nothing is saved.
- **When a change takes effect.** Every setting falls into one of three groups:

  | Label | Meaning |
  |---|---|
  | **Live** | Applies immediately, even mid-flight. |
  | **Live while parked** | Applies immediately while you're parked with no clearance issued. After that, the flight plan is locked ("flight plan locked after clearance"). |
  | **Restart** | Saved now, and a *"restart xatc to apply"* banner appears. It takes effect the next time xatc starts. |
- **Command-line overrides:** every `xatc run` flag still works, as a **one-run override**.
  - Precedence is **flag, then settings file, then default**.
  - A flag is **never written back** to the file.
  - While a flag is set, the Settings page shows that field read-only, marked *"set by command
    line"* -- for every section, including Connection, Voice and Advanced, not just Flight and ATC.
  - `--replay` and `--weather-fixture` exist only on the command line, because they're
    development tools.
- **No secrets are stored.** xatc stores only the *name* of your AWS profile and region, never
  keys or tokens. Credentials stay with the AWS CLI (`aws login`, SSO or `aws configure`).

---

## Flight

The flight plan xatc builds your clearances from. Changes are **live while parked**.

| Setting | Default | Flag | What it does |
|---|---|---|---|
| **Flight rules** (`flight_plan.flight_rules`) | IFR | `--flight-rules` | **IFR** flies a full clearance-to-landing flight. **VFR** with destination = departure flies [pattern work](features/vfr-pattern.md); VFR to another airport departs with "frequency change approved" and can request [flight following](features/vfr-flight-following.md) -- see the hint on the toggle itself. |
| **Source** (`flight_plan.source`) | Manual | — | **Manual** uses the fields below. **SimBrief** fetches your latest OFP; use *Preview* to check it, then *Use this plan*. |
| **SimBrief user** (`flight_plan.simbrief_user`) | blank | `--simbrief-user` | Your SimBrief username or numeric user ID. It's not a secret. |
| **Callsign** (`flight_plan.callsign`) | blank | `--callsign` | As filed, e.g. `N547GA` or `ASA123`. **Blank uses the sim's tail number**, so normally you never type it. |
| **Aircraft type** (`flight_plan.aircraft_type`) | blank | `--aircraft-type` | The ICAO type designator, e.g. `GLF5`, `C172`, `B738`. **Blank uses the sim's aircraft.** It decides the spoken callsign ("Gulfstream …") and heavy-jet rules. |
| **Departure** (`flight_plan.departure`) | blank | `--departure` | The ICAO airport. **Blank picks the airport nearest your aircraft.** |
| **Destination** (`flight_plan.destination`) | blank | `--dest` | The ICAO airport. It sets the clearance limit and drives arrival planning (STAR, approach, landing runway). |
| **Route** (`flight_plan.route`) | `DCT` | `--route` | The filed route after the SID, e.g. `SEA J1 BTG`. Its first fix helps choose the SID, and its last fix helps choose the STAR. |
| **Cruise altitude** (`flight_plan.cruise_ft`) | 35000 | `--cruise` | In feet. Center climbs you to it; flight levels are spoken at or above 18,000 ft. |

With **SimBrief** as the source, any manual field you fill in overrides that single value from the
OFP. The OFP's origin becomes the departure airport.

## Connection

How xatc reaches X-Plane. Every change needs a **restart**.

| Setting | Default | Flag | What it does |
|---|---|---|---|
| **X-Plane host** (`connection.xplane_host`) | `127.0.0.1` | `--xplane-host` | Where X-Plane's Web API is reachable. Keep the default when xatc runs on the same PC as X-Plane (ADR 0006). |
| **X-Plane port** (`connection.xplane_port`) | `8086` | `--xplane-port` | The Web API port (X-Plane: *Settings → Network*). |
| **X-Plane folder** (`connection.xplane_root`) | blank | `--xplane-root` | Your X-Plane 12 install. **Blank auto-detects it** on Windows from `%LOCALAPPDATA%\x-plane_install_12.txt`. xatc reads airports, airspace, procedures and fixes straight from this folder, with Custom Scenery taking priority. |

The `XATC_XPLANE_HOST`/`XATC_XPLANE_PORT` environment variables no longer affect `xatc
run` -- use these settings (or `--xplane-host`/`--xplane-port`) instead. `xatc doctor`,
`xatc smoke` and `xatc record` still honor them.

## Voice

Push-to-talk speech in, ATC speech out. See [Voice](features/voice.md).

| Setting | Default | Flag | When | What it does |
|---|---|---|---|---|
| **Voice enabled** (`voice.enabled`) | off | `--voice` | restart | Turns on Amazon Transcribe (your speech) and Polly (ATC's replies). Off means text only: you type transmissions in the panel. |
| **AWS profile** (`voice.aws_profile`) | `xatc` | — (`AWS_PROFILE`) | restart | The AWS CLI profile to use. Only the name is stored. |
| **AWS region** (`voice.aws_region`) | `us-east-1` | `--aws-region` | restart | Where Transcribe, Polly and Bedrock are called. |
| **Custom vocabulary** (`voice.vocabulary`) | `xatc-aviation-en-US` | `--vocabulary` / `--no-vocabulary` | restart | A Transcribe custom vocabulary name, deployed with `cdk deploy`. It improves recognition of callsigns, fixes and procedure names. **Blank, or `--no-vocabulary`, means none.** |
| **PTT joystick button** (`voice.ptt_joystick`) | blank | `--ptt-joystick` | **live** | `"<device>:<button>"` for a yoke or joystick push-to-talk button. Use **Learn PTT button** and press it within 10 s. Windows only for now. See [Joystick PTT](features/joystick-ptt.md). |
| **Radio effect** (`voice.radio_fx_preset`) | `realistic` | — | **live** | `clean` (no radio effect), `realistic` (VHF band-limit, compression, hiss, squelch) or `busy-day` (more noise). Signal strength also varies with distance. See [VHF radio effect](features/radio-fx.md). |

The panel also lists your **microphones** (the default is marked) and **joysticks** (with button
counts), so you can see what xatc detects.

## ATC

How strict ATC is, and how it understands you. Every change is **live**.

| Setting | Default | Flag | What it does |
|---|---|---|---|
| **Intent parser** (`atc.intent_parser_mode`) | disabled (fallback with `--voice` if never set) | `--intent-mode` | **Disabled:** rules only. **Fallback:** the Nova Lite LLM helps only when the rules can't understand you. **Primary:** Nova Lite first, with the rules as backup. The LLM only classifies *what you asked for*; it never writes ATC's words. See [Intent parsing & LLM modes](features/intent-parsing.md). |
| **Altitude source** (`atc.altitude_source`) | Mode C | `--altitude-source` | Which altitude the conformance monitor and handoffs judge you on. **Mode C** is what a real controller's radar shows: pressure altitude corrected to the local altimeter below FL180. **Indicated** is your cockpit altimeter. **True** is the sim's true MSL altitude. |
| **Conformance strictness** (`atc.conformance_strictness`) | normal | `--strictness` | **Relaxed:** wider tolerances, and readback errors are corrected but don't hold up the flight. **Normal.** **Checkride:** tight tolerances. See [Conformance monitor](features/conformance-monitor.md). |
| **Heavy-jet speed exception** (`atc.heavy_speed_exception`) | on | `--no-heavy-speed-exception` | When on, Heavy and Super types (747, 777, 787, A350, A380 …) aren't held to 250 kt below 10,000 ft (14 CFR 91.117(d)). An assigned speed is still enforced. |

## Advanced

Rarely needed. Every change needs a **restart**.

| Setting | Default | Flag | What it does |
|---|---|---|---|
| **apt.dat override** (`advanced.apt_dat`) | blank | `--apt-dat` | A specific apt.dat file. Blank uses your X-Plane install, else the bundled KSEA/KPDX fixtures. If set, also set **Departure**. |
| **atc.dat override** (`advanced.atc_dat`) | blank | `--atc-dat` | A specific atc.dat for Center airspace and frequencies. Blank uses your X-Plane install, else the bundled excerpt. |
| **Debrief folder** (`advanced.debrief_dir`) | blank (off) | `--debrief-dir` | Record every session here: a JSONL log plus a Markdown summary with a timeline, deviations, readbacks and radio events. See [Debrief](features/debrief.md). |
| **Panel address** (`advanced.panel_host`) | `127.0.0.1` | `--host` | Where the radio panel is served. Use `0.0.0.0` to open it from a tablet on your network. |
| **Panel port** (`advanced.panel_port`) | `8000` | `--port` | The radio panel's port: `http://localhost:8000`. |

---

## Example `settings.json`

```json
{
  "schema_version": 1,
  "flight_plan": {
    "flight_rules": "IFR",
    "source": "manual",
    "simbrief_user": "",
    "callsign": "",
    "aircraft_type": "",
    "departure": "",
    "destination": "KPDX",
    "route": "DCT",
    "cruise_ft": 35000
  },
  "atc": {
    "intent_parser_mode": "fallback",
    "altitude_source": "mode_c",
    "conformance_strictness": "normal",
    "heavy_speed_exception": true
  },
  "voice": {
    "enabled": true,
    "aws_profile": "xatc",
    "aws_region": "us-east-1",
    "vocabulary": "xatc-aviation-en-US",
    "ptt_joystick": "",
    "radio_fx_preset": "realistic"
  },
  "connection": { "xplane_host": "127.0.0.1", "xplane_port": 8086, "xplane_root": "" },
  "advanced": { "apt_dat": "", "atc_dat": "", "debrief_dir": "", "panel_host": "127.0.0.1", "panel_port": 8000 }
}
```

You can edit the file by hand while xatc isn't running. If the file doesn't validate, for
example because of a typo in an enum value, xatc logs a warning and starts with **all defaults**
(the file itself is left alone), so keep a copy before hand-editing. The Settings page is the safer
route, because it validates each field before saving.

## Command-line only

These are development and diagnostic tools, not settings:

| Command / flag | Purpose |
|---|---|
| `xatc run --replay <file.jsonl>` | Replay a recorded flight instead of connecting to X-Plane. |
| `--weather-fixture north-flow\|south-flow` | Fixed weather for replay. |
| `xatc doctor [--check-aws]` | Checks your install, the X-Plane Web API, AWS credentials and the microphone. See [Getting Started](getting-started.md#running-on-windows). |
| `xatc smoke --live` | A hands-on check against a running X-Plane: live state, COM tuning, weather, a joystick-button watch, and optionally a Polly phrase. |
| `xatc ptt-probe` | Lists joysticks and shows button presses, to find your PTT button. |
| `xatc debrief <session.jsonl>` | Rebuilds a debrief summary from a session log. |
