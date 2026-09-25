# Fuzzy ramp resolver

**In progress: built, not yet wired into taxi routing.**

## What it does

`xatc.world.ramp_resolver.RampResolver` turns what you actually say -- "Cessna 12345 at
the Signature ramp," "at gate bravo twelve," "cargo two dash one," "on Alpha near the
FBO" -- into a specific taxi-graph node, tolerant of ASR spelling mistakes and loose
wording. `resolve(phrase, lat, lon) -> RampResolution` is pure (no I/O; loading an alias
file happens once, separately) and returns a match, a confidence score, and whether the
result needs the pilot to confirm it.

## How it decides

1. **Normalizes** both the phrase and every candidate name first: lowercase and strip
   punctuation, expand the phonetic alphabet ("alfa," "x-ray"), turn spoken numbers into
   digits ("one one," "eleven," and "one-one" all become 11; "niner," "tree," and "fife"
   are understood too), join a letter to the digits that follow it ("a 11" → "a11"), and
   only look at the text after the first "at" or "on" so a leading callsign doesn't leak
   into the match.
2. **Candidates** come from apt.dat parking stands, taxiway names, sign/place labels
   (e.g. cargo ramp signage), and an optional per-airport alias file.
3. **Scores** each candidate with a fuzzy string match or a phonetic (Double Metaphone)
   match, whichever is higher -- but a candidate whose digits or stand code weren't
   actually said is capped well below the match threshold, so "Alpha eleven" can never
   resolve to A12 just because A12 happens to be nearby.
4. **Ranks** by score plus how much of the phrase the candidate explains, minus a
   distance penalty -- so a vague phrase that several candidates explain equally well
   lands on whichever one is actually closest to the aircraft.
5. **Decides what to return**:
   - A confident match close to the aircraft is used directly.
   - Anything weaker falls back to the nearest taxi-graph node to the aircraft's real
     sim position -- the same "ground truth wins" default [taxi
     routing](taxi-routing.md) already uses everywhere.
   - A confident match that's still far from the aircraft (currently 300 m) is treated
     as a likely disagreement: the sim position is used, but the result is flagged as
     needing confirmation, naming what was actually heard.

## Configuration

An optional per-airport alias file (YAML) maps informal names -- an FBO or company ramp
name apt.dat doesn't itself encode -- onto real parking stands, weighted toward whichever
one is nearest the aircraft.

## Limitations

- **Not called from the engine at all yet.** [Taxi routing](taxi-routing.md) still
  always starts from the aircraft's live sim position, full stop -- nothing in the
  engine passes a pilot's spoken location into this resolver today.
- No dedicated path for taxi-in yet (resolving a destination ramp with no sim-position
  contradiction to check against).
- A callsign spoken without "at"/"on" immediately before the location could leak stray
  letters into the match; the resolver depends on the intent parser eventually passing
  it just the location phrase.
