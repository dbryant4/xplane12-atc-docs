# VFR Class B/C/D airspace entry

**Available now.**

## What it does

A VFR flight nearing a Class B, C or D airport is expected to establish the right kind
of contact before entering -- xatc checks for it, independent of flight phase, for as
long as the loaded `atc.dat` has that airspace and its controlling position is staffed.
IFR flights are never checked here -- 14 CFR 91.131/130/129 only bind VFR.

## Class B: request a clearance

Class B needs an explicit request -- say *"request Bravo clearance"* (or "request
clearance into the Class Bravo") to whichever facility owns it. Approved: *"cleared into
the Class Bravo airspace, maintain VFR at or below four thousand"* -- the altitude is the
next 500 ft above your current one (minimum 2,500 ft, capped at the Class B's own
ceiling). Asking as an IFR flight, or asking a facility that doesn't own a Class B, gets
*"say again"*.

A VFR takeoff automatically clears you into your own departure airport's Class B, if it
has one -- no separate request needed there.

**Entering without a clearance** gets an escalating callout: *"you are in Class Bravo
airspace without a clearance, remain outside Class Bravo airspace"*, gentle through
"possible pilot deviation".

**Climbing above your cleared altitude** (F10) gets its own callout: *"check altitude,
maintain VFR at or below four thousand"*, then *"maintain VFR at or below four
thousand"*, then a deviation -- the tolerance scales with [conformance
strictness](conformance-monitor.md) the same way every other altitude tolerance does.

## Class C and D: two-way contact is enough

Class C and D don't need a request at all -- ordinary two-way radio contact satisfies
it: any transmission from that facility that uses your callsign. Enter before that's
happened and you get an escalating callout naming the airspace: *"you entered Class
Charlie airspace without establishing communications"* (or *"Class Delta"*).

## Out of scope

- **Sequencing behind other traffic** ("number two, follow the...") is not implemented
  here -- see the [roadmap](../roadmap.md) for M7-3.
