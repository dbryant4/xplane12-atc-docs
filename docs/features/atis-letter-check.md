# ATIS letter check

**Available now.**

## What it does

Real controllers expect a pilot's first call to include the current ATIS information
letter (FAA JO 7110.65 2-9-3) -- xatc checks for it on **initial contact** with a
position, and reminds you if it's missing or stale:

- **No letter said at all** -- the reply adds *"advise you have information Alpha"* (the
  current letter) onto whatever ATC was already about to say.
- **An old letter** -- the reply adds *"information Bravo is current, altimeter two
  niner six two"*, giving you the new letter and the altimeter setting together.
- **The current letter** -- nothing is added; the reply goes out as it normally would.

This is appended to the clearance, taxi instruction, or pushback approval you're
already getting -- it's never its own standalone transmission, and it's never something
you have to read back. It's plain engine logic, not a fourth [conformance
monitor](conformance-monitor.md).

## Where it's checked

Only on **initial contact**, once per position per flight -- calling the same position
again later doesn't re-check it:

- **Clearance Delivery**, when you first request your clearance.
- **Ground**, when you first request taxi (checked independently of Clearance -- if you
  skip Clearance and go straight to Ground, Ground checks it itself).
- **Destination Approach**, on your first check-in there (the destination ATIS letter,
  not your departure's -- and no altimeter is appended in this case, since Approach's
  reply already carries one).

Departure, Tower, and Center never check it -- by the time you're talking to them,
you've already had at least one initial-contact check.

## Limitations

- The check only fires on the *first* call to a position, not on every subsequent
  transmission -- there's no ongoing enforcement that you keep using the current letter.
