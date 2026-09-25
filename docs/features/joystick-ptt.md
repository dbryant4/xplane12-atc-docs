# Joystick/yoke push-to-talk

**Available now on Windows.** Refused with a clear message on macOS -- not a bug, see
below.

## What it does

A physical joystick or yoke button now works as push-to-talk, alongside the radio
panel's on-screen button and the browser's held-Space-key binding -- all three trigger
the exact same key-up, so the TX light and transcript behave identically no matter which
one you actually use.

```bash
xatc run --live --voice --ptt-joystick "CH Yoke:7"
```

If you don't already know your button's number:

```bash
xatc ptt-probe
```

lists every connected joystick and yoke, then prints each button's number as you press
and release it -- so you can find the right one without guessing.

## How it's wired up

`xatc.voice.ptt_input` polls the chosen button (SDL, via the `pygame-ce` joystick
module) in a background thread, and fires the same `ptt_down`/`ptt_up` path the panel's
own button uses -- there's no separate, shortcut code path for a hardware button that
might behave slightly differently from the on-screen one.

`--ptt-joystick` takes `"<device name or index>:<button>"` -- either the device's index
(`"0:7"`) or a case-insensitive substring of its name (`"CH Yoke:7"`), whichever
`xatc ptt-probe` showed you. A device name that doesn't match anything connected, or
matches more than one device ambiguously, is a clean startup error naming what's
actually plugged in, not a crash.

## Why macOS is refused

SDL (the library behind the joystick support here) expects its event pumping to happen
on the main thread. Polling in a background thread -- needed so the rest of `xatc` keeps
running normally while it waits for a button press -- is fine on Windows, which is
where `xatc` actually runs for a real flight (see [Any-airport data
loading](any-airport-data.md) and ADR 0006 in the repository), but can crash the
process on macOS. Rather than risk that, `--ptt-joystick` checks the platform and
refuses to start there, with a message explaining why. `xatc ptt-probe` is unaffected,
since it polls from the main thread and never starts that background thread at all -- it
works fine on macOS for finding a button number ahead of time, even though actually
using it for `--ptt-joystick` has to wait until you're on the Windows PC.

## Why `pygame-ce`

Chose SDL (via `pygame-ce`'s `joystick` module) over a raw `hid` binding or the `inputs`
package: SDL enumerates an arbitrary joystick or yoke's full button set the same way for
any device it recognizes, which a generic "any device, any button" binding needs --
`inputs` has much narrower generic-joystick coverage (mostly Xbox-style controllers),
and `hid` would need this module to know each device's raw HID report layout itself.
Specifically `pygame-ce` (an actively maintained, API-compatible fork of the original
`pygame`, still `import pygame`), not plain `pygame`: plain `pygame`'s newest release
predates Python 3.14 and ships no wheel for it, which would mean building it from source
in CI -- `pygame-ce` publishes one for every platform this project runs on.

## Limitations

- **Not yet confirmed against real hardware.** The polling logic, spec parsing, and
  device resolution are all thoroughly unit-tested against a fake backend, and the real
  backend constructs and enumerates cleanly on a machine with no joystick attached, but
  the actual "press a real button, hear it key up" path hasn't been exercised against
  real hardware yet.
- **Windows only**, by design -- see above.
- **Research, not implemented:** X-Plane's own Settings → Joystick screen can already
  bind a physical button to an arbitrary X-Plane command, and if X-Plane exposes the raw
  hardware button state as a dataref, `xatc` could in principle read PTT directly
  through the same sim bridge it already has for `AircraftState`, with no extra library
  and no separate device handle at all. Not confirmed against a live X-Plane Web API, so
  not built -- noted as a possible simplification for later.

## Verification

Unit tests cover spec parsing (including a device name that itself contains a colon),
device resolution (by index, by name substring, an ambiguous match, no match, no
devices connected at all), the press/release polling loop (fires once per press, once
per release, never repeatedly while held, never fires if the button's never pressed),
and `xatc ptt-probe`'s device listing and press/release output -- all against a fake
backend, no pygame import needed anywhere except the real backend itself, which is never
exercised in tests. Separately, tests confirm a joystick trigger reaches the exact same
panel code the WebSocket-driven on-screen button and keyboard binding use, that the
joystick's pygame resources are released in every case (a resolve failure, the macOS
refusal, and a normal shutdown), and that macOS is refused cleanly with the backend it
already opened to check the device closed again right away.
