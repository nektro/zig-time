id: iecwp4b3bsfmpp4x99gjo4a5ljv6ix4owy8czip32yanpvlb
name: time
main: time.zig
license: MIT
description: A date and time parsing and formatting library for Zig.
dependencies:
  - src: git https://github.com/nektro/zig-extras
  - src: git https://github.com/nektro/zig-sys-linux
  - src: git https://github.com/nektro/zig-sys-darwin
  - src: git https://github.com/nektro/zig-nio
root_dependencies:
  - src: git https://github.com/nektro/zig-expect
  - src: git https://github.com/nektro/zig-nfs
  - src: git https://github.com/nektro/zig-nio
  - src: git https://github.com/nektro/zig-extras

  - src: git https://github.com/eggert/tz
    id: xw6xua7fqgft9ezk64mdj4nirj4hlz6s84vy2n5gu9ihrwuu
    license: CC0-1.0
    keep: true
