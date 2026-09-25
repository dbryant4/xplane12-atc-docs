# Pushback

**Available now.**

## What it does

Request pushback from Ground before you start taxiing, and xatc works out which way
your tail actually needs to go and approves it: *"push back approved, tail south."*
Pushback is its own flight phase, between the clearance and taxi-out, and only Ground
handles it -- asking Tower gets redirected with *"contact Seattle Ground."*

The tail direction comes from real geometry, not a guess: xatc looks for a taxilane
behind your stand, on the way toward your departure runway, and works out which way the
nose ends up pointing once you're pushed onto it -- the tail is the opposite direction.
With no usable taxilane nearby, it defaults to a straight push, tail opposite your
parked heading.

Pushback has to be requested -- it's never automatic -- and it's only available while
the aircraft is still on the ground and hasn't started taxiing yet: ask after taxi has
begun and you'll get *"say again"* instead.

**IFR flights need their clearance first.** Ask for pushback (or taxi) before you've
gotten your IFR clearance and Ground won't approve it -- you'll get *"clearance on one
two eight point zero"* (Clearance Delivery's frequency) instead, and nothing changes
until you go get it. A field with no separate Clearance Delivery has Ground issue the
clearance itself rather than send you somewhere that doesn't exist. **VFR flights skip
this entirely** -- there's no IFR clearance to wait for, so Ground approves pushback and
taxi straight away.

## Conformance tie-in

Pushing back without asking isn't invisible: moving more than 50 m from where you were
parked, without a pushback or taxi clearance, is caught by the same [taxiing-without-
clearance rule](conformance-monitor.md#ground-conformance) that catches an unauthorized
taxi -- slow pushback creep stays under the taxi *speed* threshold, but not this
distance check. Once pushback (or taxi) is actually approved, the check stops applying.

See also: [VFR pattern work](vfr-pattern.md), which always uses this no-clearance-needed
Ground path.
