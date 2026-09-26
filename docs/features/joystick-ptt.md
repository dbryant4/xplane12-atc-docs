# Push-to-talk from hardware

**Available now.** A physical yoke or joystick button works as push-to-talk, alongside
the radio panel's on-screen button and the browser's held-Space-key binding -- all
three trigger the exact same key-up, so the TX light and transcript behave identically
no matter which one you use. Configure this from the [Settings
page](radio-panel.md#settings)'s Voice tab -- see [Settings reference](../settings.md)
for the full field list.

`voice.ptt_source` picks how: **X-Plane** (the default), **Joystick**, or **Off**.

## X-Plane

Reads `sim/joystick/joystick_button_values` -- X-Plane's own array of every joystick
button's current state -- straight over the Web API connection `xatc` already has open
for `AircraftState`. Confirmed live against the owner's real yoke on Windows (X-Plane
12.4.3): the PTT button showed up at index 1441. No extra library and no SDL are
involved, so unlike the Joystick source below, this works on macOS too.

Click **Learn PTT button** on the Voice tab, then press the button on your yoke or
joystick: xatc watches the array for up to 10 seconds and fills in the index that
changed. This needs a live X-Plane connection -- there's nothing to read from during a
replay session, and the button click reports a clear error rather than hanging if you
try it during one.

Switching to or away from this source, or changing the button index, applies
immediately -- no restart needed.

## Joystick

The original approach, kept as a fallback for a device X-Plane doesn't expose a usable
button index for: `xatc.voice.ptt_input` polls a chosen button via SDL (the `pygame-ce`
joystick module) in a background thread.

The Voice tab's Joystick PTT field takes `"<device name or index>:<button>"` -- either
the device's index (`"0:7"`) or a case-insensitive substring of its name (`"CH
Yoke:7"`). **Learn PTT button** works here too, watching every connected device's every
button instead of one array. A device name that doesn't match anything connected, or
matches more than one device ambiguously, is a clean error naming what's actually
plugged in, not a crash. If you'd rather find a button number yourself first:

```bash
xatc ptt-probe
```

lists every connected joystick and yoke, then prints each button's number as you press
and release it.

### Why macOS refuses this source

SDL (the library behind Joystick PTT) expects its event pumping to happen on the main
thread. Polling in a background thread -- needed so the rest of `xatc` keeps running
normally while it waits for a button press -- is fine on Windows, which is where `xatc`
actually runs for a real flight (see [Any-airport data loading](any-airport-data.md) and
ADR 0006 in the repository), but can crash the process on macOS. Rather than risk that,
this source checks the platform and refuses to start there, with a message explaining
why -- pick **X-Plane** or **Off** instead. `xatc ptt-probe` is unaffected, since it
polls from the main thread and never starts that background thread at all -- it works
fine on macOS for finding a button number ahead of time.

### Why `pygame-ce`

Chose SDL (via `pygame-ce`'s `joystick` module) over a raw `hid` binding or the `inputs`
package: SDL enumerates an arbitrary joystick or yoke's full button set the same way for
any device it recognizes, which a generic "any device, any button" binding needs --
`inputs` has much narrower generic-joystick coverage (mostly Xbox-style controllers),
and `hid` would need this module to know each device's raw HID report layout itself.
Specifically `pygame-ce` (an actively maintained, API-compatible fork of the original
`pygame`, still `import pygame`), not plain `pygame`: plain `pygame`'s newest release
predates Python 3.14 and ships no wheel for it, which would mean building it from source
in CI -- `pygame-ce` publishes one for every platform this project runs on.

## Off

No hardware push-to-talk at all -- the on-screen button and the Space-key binding still
work.

## Limitations

- **Joystick specifically hasn't been confirmed against real hardware** -- its polling
  logic, spec parsing, and device resolution are all thoroughly unit-tested against a
  fake backend, and the real backend constructs and enumerates cleanly on a machine with
  no joystick attached, but the actual "press a real button, hear it key up" path hasn't
  been exercised against real Joystick-source hardware. (X-Plane, above, has.)
- **Joystick is Windows only**, by design -- see above.

## Verification

Unit tests cover spec parsing (including a device name that itself contains a colon),
device resolution (by index, by name substring, an ambiguous match, no match, no
devices connected at all), the press/release polling loop for both sources (fires once
per press, once per release, never repeatedly while held, never fires if the button's
never pressed), `xatc ptt-probe`'s device listing and press/release output, and
`XPlaneWebApiBridge.dataref_stream` against a real local fake X-Plane Web API server --
all without needing pygame installed, real hardware, or a real X-Plane connection.
Separately, tests confirm a trigger from either source reaches the exact same panel code
the WebSocket-driven on-screen button and keyboard binding use, that the Joystick
source's pygame resources are released in every case (a resolve failure, the macOS
refusal, and a normal shutdown), and that hot-swapping `ptt_source` mid-session starts
and stops the right one.
