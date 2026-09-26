# En-route pilot requests

**Available now.**

## What it does

Four things a pilot can ask for once airborne and talking to whichever position
currently owns the aircraft (Departure, Center, or Approach): a direct routing, an
altitude change, a weather deviation, or declining an outstanding instruction with
"unable." Asking any of these on a frequency that *isn't* currently working you gets
*"say again"* instead.

### Direct-to

*"Request direct Battle Ground"* -- approved with *"cleared direct Battle Ground"* for
any fix on your filed route, your destination STAR's entry/transition fix, or any other
fix on the currently tracked route (see [Route tracking](route-tracking.md)); otherwise
denied with *"unable, Battle Ground is not on your route."* Asking direct to a fix
you've already passed gets a different denial instead -- *"unable, Battle Ground, that's
behind you"* -- rather than clearing you backward along your own route. An approved
direct-to drops any assigned heading and **is read back** -- get it wrong and you'll
hear *"negative, cleared direct Battle Ground."*

### Altitude change

*"Request higher,"* *"request lower,"* or a specific *"request flight level three nine
zero"* / *"request one two thousand."* "Higher"/"lower" moves you 2,000 ft from your
current assignment. Approved with *"climb and maintain..."*, *"descend and
maintain..."*, or *"maintain..."* (if the request resolves to your current altitude),
and **is read back** the same way any altitude assignment is. Outside 1,000-45,000 ft,
or if the request can't be parsed, you get a bare *"unable"* or *"say again the
altitude"* -- and nothing changes.

### Weather deviation

*"Request deviation 20 degrees right"* (or left, with or without a degree count) --
always approved: *"deviation 20 degrees right approved, advise when able to proceed
direct Battle Ground"* (the next fix on your route or STAR), falling back to *"...proceed
on course"* if there's no next fix to name. A deviation drops your assigned heading the
same way a direct-to does, but unlike direct-to and altitude changes, **a deviation is
not read back**.

### "Unable"

Saying *"unable"* declines whatever you were just cleared for. If there's a pending
readback, that instruction is rolled back to whatever stood before it, and ATC
confirms what you're still on: *"roger, maintain flight level three five zero,"*
*"roger, fly heading..."*, or, for a direct-to being taken back, *"roger, resume own
navigation."* With nothing pending, it's just *"roger."*

## Conformance implications

An approved direct-to or altitude change updates the same clearance the [airborne
conformance monitor](conformance-monitor.md#airborne-conformance) checks against, so
approving one immediately changes what you're expected to fly. A deviation does the
same for heading, but -- since it isn't read back -- there's nothing pinning you to a
specific new course beyond "proceed direct" or "on course" once you're able.

## Limitations

- The engine doesn't yet assign headings outside of a deviation/direct-to's own
  bookkeeping, so there's nothing for the heading conformance rule to clear against a
  "resume own navigation" instruction yet.
