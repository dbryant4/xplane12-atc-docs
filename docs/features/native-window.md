# Native window

**Available now.**

## What it does

Running `xatc` with no arguments opens the radio panel in its own titled **"xatc"**
window instead of a browser tab -- a native desktop window (via
[pywebview](https://pywebview.flowrl.com/)), using whatever web-rendering engine the OS
already ships: Edge WebView2 on Windows (bundled with Windows 10/11, nothing for xatc to
install), WebKit on macOS, GTK's WebKit port on Linux.

- **The window remembers its size and position** between runs, saved next to
  `settings.json`. Delete that file to reset both to the default size, centered.
- **Always on top** (Settings → Display) keeps the window above X-Plane, live -- toggle
  it mid-flight with no restart.
- **Closing the window** shuts xatc down the same graceful way Ctrl+C does in a
  terminal: the voice session stops, flight state saves, and an in-progress AWS sign-in
  is cancelled cleanly.
- **A tablet or another device on the LAN** still reaches the panel through its browser
  either way -- the native window is just how the panel opens on the machine actually
  running xatc; the panel itself is still served over the network the same as always.

## Browser mode

Prefer the old browser-tab behavior, or pywebview isn't available on your machine?

- **`xatc --browser`** forces it for that one run, regardless of the setting below.
- **Settings → Display → Window = Browser** (`display.window`, default `Native`) makes
  it the default every time. This one needs a **restart** to take effect -- there's no
  live way to turn an already-open browser tab into a native window, or back.

If a native window isn't actually usable on this machine -- pywebview itself isn't
installed, or on Windows, the Edge WebView2 runtime isn't (pywebview silently falls back
to the ancient MSHTML/IE11 engine otherwise, which can't render the panel at all) --
xatc falls back to opening the browser automatically, with one line in the log saying
why.

## Window state file

| OS | Path |
|---|---|
| Windows | `%LOCALAPPDATA%\xatc\window.json` |
| macOS | `~/Library/Application Support/xatc/window.json` |
| Linux | `~/.config/xatc/window.json` |

Written once, when the window closes -- not on every resize or move -- next to
`settings.json`. Skipped if the window is minimized at the time (a minimized window's
reported size and position are bogus, not its real, restored geometry), so the last good
size and position are kept instead. A missing or unreadable file just means the window
opens at its default size and position
-- it's never required for xatc to start.

## Configuration

See the **[Settings reference](../settings.md#display)** for `display.window` and
`display.always_on_top`.

## Limitations

- Sizing and position are per-machine, not synced anywhere -- there's one `window.json`
  per settings folder, same as `settings.json` itself.
- The window title is always plain "xatc" -- it doesn't show the callsign or flight
  phase.
