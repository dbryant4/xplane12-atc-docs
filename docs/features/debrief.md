# Post-flight debrief

**Available now.**

## What it does

```bash
xatc run --debrief-dir debrief/ --live ...
```

Records every ATC transmission, pilot transmission, and [conformance
monitor](conformance-monitor.md) call during the session to a log file, and writes a
Markdown summary of the flight once the session ends -- so you (or an instructor) can
review a flight afterward instead of only catching it in the moment.

The log is a plain JSONL file, one record per line, named `xatc-YYYYMMDD-HHMMSS.jsonl`
in the directory you gave. Each record is flushed to disk immediately, so a crash mid-
session still leaves a usable log of everything up to that point.

## The Markdown summary

Written automatically when the session ends, and regeneratable any time from an
existing log with:

```bash
xatc debrief debrief/xatc-20260925-171500.jsonl
```

It contains:

- A start time and a one-line stat summary (radio call count, conformance call count,
  and total sim time covered).
- A **Timeline** table of every ATC and pilot transmission plus every conformance
  event, in order -- with routine ATIS broadcasts left out, since they just repeat on a
  loop and would otherwise dominate the table.
- A **Deviations** section, grouped under "Possible pilot deviations," "Firm
  corrections," and "Gentle reminders" (matching the [conformance
  monitor](conformance-monitor.md)'s own escalation levels), each entry naming the rule,
  the reason, and the runway or taxiway involved where relevant. A flight with no
  conformance calls at all just says so plainly.
- A **Readbacks** section: a count of how many of the flight's [readbacks](readback-checking.md)
  were correct out of the total checked, then one line per problem readback naming what
  kind it was and exactly what was wrong or missing. A flight with none checked, or none
  with a problem, says so plainly rather than an empty section.

## Limitations

- The log format only exists for `xatc run`; there's no equivalent for the replay-only
  `xatc panel` command.

## Verification

Unit tests cover writing and reading back every record kind, the JSON Lines format
surviving a crash mid-write, the exact Markdown output for a representative session
(including the empty-timeline and no-conformance-calls cases), and the standalone `xatc
debrief` command regenerating a summary from a log without re-running anything.
