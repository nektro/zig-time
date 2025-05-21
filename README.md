# zig-time

![loc](https://sloc.xyz/github/nektro/zig-time)
[![license](https://img.shields.io/github/license/nektro/zig-time.svg)](https://github.com/nektro/zig-time/blob/master/LICENSE)
[![nektro @ github sponsors](https://img.shields.io/badge/sponsors-nektro-purple?logo=github)](https://github.com/sponsors/nektro)
[![Zig](https://img.shields.io/badge/Zig-0.14-f7a41d)](https://ziglang.org/)
[![Zigmod](https://img.shields.io/badge/Zigmod-latest-f7a41d)](https://github.com/nektro/zigmod)

Exposes a `DateTime` structure that can be initialized and acted upon using various methods. All public methods return a new structure.

Currently handles dates and times based on the [Proleptic Gregorian calendar](https://en.wikipedia.org/wiki/Proleptic_Gregorian_calendar) in adherence to [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601).

Does not currently support time zones outside of UTC.

Does not handle leap seconds.

See the `FormatSeq` structure for display information on what to pass as a `fmt` string.
