# zig-time

Exposes a `DateTime` structure that can be initialized and acted upon using various methods. All public methods return a new structure.

Currently handles dates and times based on the [Proleptic Gregorian calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar) in adherence to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601).

Does not currently handle leap seconds.

See the `FormatSeq` structure for display information on what to pass as a `fmt` string.
