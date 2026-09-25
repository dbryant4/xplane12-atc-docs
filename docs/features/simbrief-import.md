# SimBrief import

**Available now.**

## What it does

```bash
xatc run --simbrief-user <username or numeric ID> --live
```

`xatc` fetches your latest SimBrief OFP (Operational Flight Plan) and builds the flight
plan from it -- callsign, aircraft type, departure, destination, route, cruise altitude,
and SID -- instead of you typing every flag by hand.

Any flight-plan flag you *do* give explicitly (`--callsign`, `--aircraft-type`,
`--departure`, `--dest`, `--route`, `--cruise`) overrides the matching field from the
OFP, so `--simbrief-user` can be combined with a manual override for just the one thing
you want different this flight.

## Where each field comes from

`xatc.flightplan.simbrief.fetch_ofp`/`parse_ofp` read SimBrief's own JSON OFP format:

- **Callsign**: the flight's ATC callsign if SimBrief has one, else the airline ICAO
  code plus flight number, else the aircraft's own registration.
- **Aircraft type**: the OFP's ICAO aircraft type designator.
- **Departure / destination**: the OFP's origin and destination ICAO codes.
- **Cruise altitude**: the OFP's initial cruise altitude.
- **SID**: the OFP's own filed SID identifier if present, else inferred from the first
  navlog fix flagged as part of a SID/STAR.
- **Route**: the OFP's filed route string, with any leading SID token and trailing STAR
  token stripped -- `xatc`'s own `FlightPlan.route` is specifically the route *after*
  the SID (see [SID & departure procedures](sid-departure-procedures.md)), so a raw OFP
  route would otherwise duplicate it. Falls back to `"DCT"` if nothing's left after
  stripping.

## Error handling

A blank username, an invalid or unknown SimBrief user, a network failure, or an OFP
missing a required field all fail the same way: a clear `xatc run: --simbrief-user: ...`
message on stderr and a clean exit, rather than a stack trace or a half-built flight
plan. There's no caching -- every `--simbrief-user` run fetches fresh.

## Limitations

- No local caching of a fetched OFP; a flaky connection means a failed run, not a stale
  fallback.
- Only the fields `xatc` actually models are extracted -- SimBrief's much larger OFP
  (fuel planning, alternates, full navlog, weather briefing) is otherwise ignored.

## Verification

Unit tests cover field extraction from a real (synthetic, non-personal) sample OFP
fixture, each of the fallback chains above (callsign, SID, route stripping), and every
error case (blank username, a non-success SimBrief response, malformed JSON, a missing
required field) -- all against an injected HTTP client, so tests never make a real
network call.
