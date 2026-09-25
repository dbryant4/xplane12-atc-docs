# Emergencies and special squawks

**Available now.**

## What it does

A distress or urgency call outranks everything else xatc is doing. Say *"mayday"* or
*"pan-pan"* on any staffed frequency, or squawk **7700**, and ATC responds immediately
with *"roger, say souls on board and fuel remaining,"* at urgent priority, ahead of
anything else queued. Whatever you answer with gets a bare *"roger."*

Two related codes get their own handling:

- **7600** (lost communications / NORDO) -- ATC transmits *"if you hear this
  transmission, ident"* and then expects nothing further from you: no readbacks, no
  check-in reminders, and any pending readback or handoff is cleared.
- **7500** (unlawful interference) -- ATC verifies discreetly, once: *"verify squawking
  seven five zero zero."*

A squawk code is only answered once, the first time you dial it in -- leaving it set
doesn't repeat the call. Declaring an emergency by voice or by squawk both count as the
same event, so whichever comes first is the one that triggers the response.

## Everything else goes quiet

Once an emergency, lost-comms, or hijack code is active, every spoken [conformance
callout](conformance-monitor.md) is suppressed for the rest of the flight -- you won't
get called out for an altitude bust or a taxiway excursion while you're handling a real
emergency. The events still happen and still reach the [debrief](debrief.md); they're
just not spoken over the radio. None of 7500/7600/7700 is itself treated as a "wrong
squawk" conformance violation.

## Limitations

- Detection isn't gated on transponder mode -- squawking 7700 with the transponder off
  or in standby still triggers the response today.
- There's no way to cancel an emergency once declared (voice or squawk) -- it stays
  active, and callouts stay suppressed, for the rest of the flight.
- No automated test exercises declaring an emergency *during* a pushback specifically,
  though the code checks for one ahead of the pushback-acknowledgement shortcut, so it
  takes priority regardless of phase.
