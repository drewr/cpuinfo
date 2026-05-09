# cpuinfo

Prints basic CPU information for the host machine.

```
Architecture : x86_64
Compile-time : athlon_xp
Cores        : 8
Runtime      : Intel Core Processor (Broadwell, no TSX, IBRS)
```

## Build

Requires [Zig](https://ziglang.org/) 0.16.0.

```sh
zig build run
```

## Platform support

| Platform | CPU model source |
|----------|-----------------|
| Linux    | `/proc/cpuinfo` |
| macOS    | `sysctlbyname("machdep.cpu.brand_string")` |
