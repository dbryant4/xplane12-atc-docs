# SID & departure procedures (CIFP)

**Available now.**

## What it does

ATC can now actually assign a Standard Instrument Departure, instead of only ever
echoing whatever SID happened to be on your filed flight plan. A real clearance:

```
cleared to Portland International airport, via the Summa Two departure,
Pangl transition, then as filed, climb and maintain five thousand,
expect one zero thousand ten minutes after departure,
departure frequency one two five point four, squawk four five two one
```

When there's no matching SID at all (no CIFP data for the airport, or nothing in the
data fits the flight plan), the clearance falls back to the pre-CIFP wording:

```
via radar vectors, then as filed
```

## Where the procedure data comes from

`xatc.world.cifp` parses the FAA's CIFP (Coded Instrument Flight Procedures) format --
ARINC 424-18, the same fixed-column format used across the industry -- from a
`FAACIFP18` file. It reads airport procedure records: terminal waypoints, SID/STAR/
approach legs, and runways, skipping the record types this project doesn't need yet
(ILS, MSA, path points, continuation records).

`parse_cifp`/`load_cifp` build a `CifpAirport`, exposing `.sids`, `.stars`, and
`.approaches` as `Procedure` objects, each with its runway and enroute transitions, its
common route, and per-leg detail (altitude/speed constraints, fly-over points, the
missed-approach point). Two real fixtures ship with the project -- `fixtures/cifp/
KSEA.arinc424` and `fixtures/cifp/KPDX.arinc424`, both from the FAA's public CIFP data
(cycle 2609, effective 2026-09-03; not for actual navigation, same as every other
fixture in this project).

## How a SID is chosen

`xatc.atc.sid_selector.select_sid(procedures, runway, flight_plan)`, in order:

1. **The filed SID**, if one was given and it actually serves the active runway.
2. Otherwise, a SID whose **enroute transition matches the first fix** of the filed
   route (an exact SID assignment beats a plausible guess); failing that, a SID whose
   **exit fix** matches that first fix. Ties are broken alphabetically by procedure
   identifier, for a deterministic result.
3. Otherwise, `None` -- radar vectors.

## How it's spoken

`say_sid("SUMMA2")` → *"Summa Two departure"*; a numbered suffix letter is spelled
phonetically (`OLM2A` → *"Olm Two Alpha departure"*, following the same pattern). The
transition name, when there is one, tries these in order:

1. A known VOR/VORTAC's real name, from a small hand-curated table
   (`xatc.phraseology.navaids.NAVAID_NAMES`, sourced from the FAA's NASR navaid data and
   covering the VORs KSEA/KPDX's own SID and STAR transitions actually use) --
   `LKV` → *"Lakeview transition"*.
2. A hand-verified pronunciation override for a fix whose plain identifier doesn't read
   naturally -- see [Pronunciation](#pronunciation) below.
3. A 5-letter fix spoken as a word -- `PANGL` → *"Pangl transition"*.
4. Anything else (a short, non-word-like ident) spelled phonetically -- *"X-ray Yankee
   Zulu transition"*.

With no transition at all, the clearance just omits that clause -- *"via the Casco Two
departure, then as filed"*.

## Pronunciation

A handful of local fix identifiers don't read naturally as plain words, so
`xatc.phraseology.fix_names.FIX_PRONUNCIATIONS` overrides them by hand:

| Fix | Spoken as |
|---|---|
| `ISBRG` | Iceberg |
| `BANGR` | Banger |
| `KNGDM` | King Dome |
| `HAWKZ` | Hawks |
| `MARNR` | Mariner |

`ISBRG`/`BANGR` come straight from real charted KSEA RNAV departures (the ISBRG ONE and
BANGR NINE); `KNGDM`/`HAWKZ`/`MARNR` come from a local pilot's-guide reference --
`KNGDM` specifically is *not* "Kingdom," it's named for the old Kingdome stadium. The
FAA doesn't publish an official pronunciation guide for fix identifiers (the naming
convention in JO 7350.9 is a *constraint*, not a lookup table), so this table is
deliberately small and hand-verified rather than guessed -- an identifier not in it
falls back to the plain word/phonetic rules above instead of a wrong guess.

## Limitations

- Only SID selection for departure is covered here -- STAR and approach selection for
  arrivals work the same way; see [Arrival](arrival.md) for the full gate-to-gate
  arrival flow.
- SID selection only considers the filed route's first fix and the filed SID itself --
  no aircraft-type-based SID restrictions (e.g. climb-gradient-only SIDs) are modeled.
- Only KSEA and KPDX have CIFP fixtures today. Any other airport falls back to "via
  radar vectors" until it gets one (or, on a real X-Plane install, until the engine
  reads CIFP data from the sim's own installation the way it already does for apt.dat
  and atc.dat -- see [Any-airport data loading](any-airport-data.md); that wiring for
  CIFP specifically is still open).

## Verification

Unit tests cover the CIFP parser against both real fixtures (procedure/leg/transition
parsing, altitude and speed constraint edge cases, runway-transition expansion like
`RW16B` matching every runway numbered 16), SID selection (filed SID, transition match,
exit-fix match, no-match fallback, tie-breaking) against real KSEA→KPDX data, and the
exact phraseology strings the renderer produces.
