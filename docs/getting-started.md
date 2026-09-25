# Getting Started

!!! note
    This mirrors the repository's own `README.md` and `infra/README.md`, which are the
    up-to-date source of truth for exact commands and flags. If anything here looks out
    of date, trust the repo.

## Prerequisites

- **X-Plane 12.1.1+**, with its built-in Web API on port 8086 (on by default). It can
  run on a different machine than xatc itself -- see [Reach X-Plane](#4-reach-x-plane)
  below.
- **Python 3.12+** and [uv](https://docs.astral.sh/uv/).
- **An AWS account**, for voice only -- Amazon Transcribe and Polly in `us-east-1`, plus
  the AWS CLI v2.
- **Node.js 22+** and the AWS CDK CLI (`npm install -g aws-cdk`), only to deploy the
  voice infrastructure once.

Everything except the AWS account is optional if you only want text mode: type
transmissions instead of speaking them, against a replayed flight, with no X-Plane and
no AWS at all.

## 1. Install

```bash
uv sync --extra voice        # drop --extra voice if you only want text mode
uv run pytest                # optional: check that everything passes
```

## 2. Deploy the voice infrastructure (one time)

This provisions two things in your AWS account, from a small CDK app in `infra/`:

- An Amazon Transcribe **custom vocabulary** (`xatc-aviation-en-US`) tuned for aviation
  phraseology -- the NATO phonetic alphabet, "niner", facility and position names,
  runway/taxiway callouts. See [Voice](features/voice.md) for how xatc uses it.
- An IAM managed policy scoped to exactly what the voice layer needs
  (`polly:SynthesizeSpeech`, `transcribe:StartStreamTranscription`,
  `transcribe:GetVocabulary`). It's **not attached to anyone automatically** -- attaching
  it to your own IAM user is a decision only you should make.

```bash
cd infra && uv sync
npx cdk bootstrap            # one time per AWS account and region
npx cdk deploy
```

`cdk deploy` prints the policy's ARN when it finishes. Attach it yourself:

```bash
aws iam attach-user-policy --user-name <your-iam-user> --policy-arn <VoicePolicyArn from the deploy output>
```

## 3. AWS credentials that stay fresh (one time)

Don't export short-lived keys into your shell -- keys from `aws login` or SSO expire
after about 15 minutes, and push-to-talk then fails with *"security token ... expired"*.
Instead, add a profile that asks the AWS CLI for fresh credentials whenever they're
needed:

```bash
printf '\n[profile xatc]\ncredential_process = aws configure export-credentials --profile default --format process\nregion = us-east-1\n' >> ~/.aws/config
```

Replace `--profile default` with whichever profile you sign in with, and check it with:

```bash
AWS_PROFILE=xatc aws sts get-caller-identity
```

If your shell already has `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` or
`AWS_SESSION_TOKEN` exported, `unset` them first -- they take priority over the profile.

## 4. Reach X-Plane

X-Plane's Web API only listens on its own machine. If X-Plane runs on a different
computer than xatc, forward the port over SSH:

```bash
ssh -fN -L 8086:127.0.0.1:8086 <user>@<xplane-host>
curl http://localhost:8086/api/capabilities     # should return JSON
```

Wait until X-Plane has **fully loaded the aircraft** before starting xatc.

## Running on Windows

For a real flight, `xatc` is meant to run **on the same Windows PC as X-Plane** (see ADR
0006 in the repository) -- no SSH tunnel needed at all, since it reads X-Plane's Web API
and its own data files locally. The SSH-tunnel setup in step 4 above is a **dev-only**
option, for developing or testing `xatc` from a different machine than the one running
X-Plane.

**One-time setup** -- from PowerShell, in the repository root:

```powershell
scripts\setup-windows.ps1
```

This installs [uv](https://docs.astral.sh/uv/) if it isn't already on your `PATH`
(printing the official install command rather than running it for you, so it never
silently installs anything without you seeing it first), runs `uv sync --extra voice`,
and finishes by running `xatc doctor` -- see below.

**Every time you fly**, double-click `scripts\xatc-run.cmd`, or run it from a terminal
with any extra flags:

```powershell
scripts\xatc-run.cmd --dest KPDX --cruise 35000
```

It sets `AWS_PROFILE=xatc` (you still need that profile configured once, per step 3
above) and runs `xatc run --live --voice`, passing through anything you give it.

### `xatc doctor`

Checks that this machine is actually ready to fly, without guessing:

```powershell
uv run xatc doctor              # add --check-aws for a live (free, read-only) API check
```

It reports Python and `uv` versions, whether an X-Plane installation was found (and
whether its `apt.dat`, `atc.dat` and CIFP data are actually there), whether X-Plane's
Web API is reachable right now, whether AWS credentials resolve, whether a microphone
is available and actually picking up sound, and where the settings file lives -- each as
a pass/warn/fail line with a fix hint, plus a summary count. `--check-aws` additionally
makes one free, read-only call each to Transcribe, Polly and Bedrock (Nova Lite) to
confirm the account actually has access, not just that credentials resolve.

## 5. Run it

From the repository root:

```bash
AWS_PROFILE=xatc uv run xatc run --live --voice \
  --callsign N547GA --aircraft-type GLF5 --dest KPDX --cruise 35000
```

Then open **http://127.0.0.1:8000**. The header should show **X-Plane 12.x ·
connected**. Hold the **PTT** button, or hold **Space** while the page has focus, to
talk -- or, on Windows, add `--ptt-joystick "<device>:<button>"` to use a real yoke or
joystick button instead (`xatc ptt-probe` finds the button number; see [Joystick/yoke
push-to-talk](features/joystick-ptt.md)). If the panel doesn't respond after an update,
hard-refresh it (Cmd+Shift+R). The first time you use push-to-talk, macOS asks for
microphone permission for your terminal app.

**Without X-Plane or AWS**, replay a recorded taxi and type your transmissions instead
of speaking them:

```bash
uv run xatc run --replay fixtures/flights/ksea_taxi_out.jsonl --weather-fixture south-flow \
  --callsign N547GA --aircraft-type GLF5 --dest KPDX --cruise 35000
```

Run `uv run xatc run --help` for every option.

## Demo script

A five-minute walkthrough of a real IFR clearance and taxi-out, at KSEA:

1. **ATIS** -- put **118.00** on COM2 and listen to the looping broadcast: wind,
   altimeter, ceiling and visibility, active runway, and an information letter.
2. **Clearance** -- put **128.00** on COM1 and say *"Seattle Clearance, November five
   four seven Golf Alpha, IFR to Portland with information Alpha."* Read the clearance
   back.
3. **Taxi** -- put **121.70** on COM1 and say *"Seattle Ground, Gulfstream five four
   seven Golf Alpha, ready to taxi with Alpha."* Read the taxi instruction back.
4. **Wrong frequency** -- transmit on a frequency nobody's listening on, and you get
   silence.

## Development

```bash
uv run pytest                          # the full suite, including the MVP acceptance test
uv run xatc record --out flight.jsonl  # record a live X-Plane session as a replay fixture
```

CI runs the suite on Python 3.12 and 3.14, with the voice extra, on Windows, and
synthesizes the `infra/` CDK app.
