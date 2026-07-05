# PC110-SeaBIOS

SeaBIOS-based replacement BIOS work for the **IBM Palm Top PC110**.

This repository takes the clean-room firmware route: start from upstream
SeaBIOS, add a PC110 hardware target, preserve useful compatibility behavior
from the IBM BIOS, and keep the result reproducible as a patch stack.

## Current Status

This is the first functional foundation, not a safe-to-flash final BIOS.

Implemented in the initial PC110 patch:

- SeaBIOS `PC110` build target.
- PC110 RAM sizing from CMOS `0x30/0x31`, with a conservative fallback.
- PC110 hardware probe logging for:
  - VL82C420 / SCAMP config signature via `0x22/0x23` gate and `0x74/0x76`.
  - power MCU register `0x00` via `0xec/0xed`.
  - PCMCIA PCIC chip ID via `0x3e0/0x3e1`.
  - key PC110 CMOS settings.
- PC110 private INT 15h compatibility:
  - `AX=5380h, BH=7fh` returns the IBM/RIOS `SLO` identify signature.
  - `AX=5380h, BX=8300h` returns an initial digitizer resource selector.
  - `AX=5000h` reports no pending private event.
  - `AX=2101h` is accepted for IBM utility compatibility.
- F1 boot prompt for IBM Easy-Setup.
- Optional build-time extraction of the compressed IBM Easy-Setup stream from a
  legally obtained PC110 BIOS dump, followed by in-BIOS LZW decompression to
  `0x50000` and entry at `5000:0000`.

## Build

Native Linux build:

```sh
./scripts/build.sh
```

macOS or other hosts without a 32-bit ELF toolchain can build in a container:

```sh
CONTAINER=1 ./scripts/build.sh
```

Debug serial build:

```sh
CONFIG_OVERLAY=configs/pc110_debug_overlay OUT_NAME=pc110-seabios-debug ./scripts/build.sh
```

To include the IBM Easy-Setup payload from your own 256 KiB dump:

```sh
PC110_BIOS_DUMP=/path/to/pc110_bios.bin ./scripts/build.sh
```

The output is:

```text
out/pc110-seabios.bin
```

## Smoke Test

CI also builds a smoke-test BIOS with the interactive boot menu disabled, then
boots it in QEMU from a tiny floppy image:

```sh
CONFIG_OVERLAY=configs/pc110_smoke_overlay OUT_NAME=pc110-seabios-smoke ./scripts/build.sh
./scripts/qemu-smoke.sh out/pc110-seabios-smoke.bin
```

The boot sector writes `PC110 BIOS BOOT OK` to COM1 and exits via QEMU's
`isa-debug-exit` device.

## Safety

Do not flash this onto a PC110 without an external programmer, a verified dump
of your original flash, and a recovery plan. The first hardware target is meant
to build, boot far enough to exercise BIOS services, and provide a structured
place for chipset initialization work.

## Upstream Base

SeaBIOS is fetched from `coreboot/seabios` at `rel-1.17.0`, pinned to commit:

```text
b52ca86e094d19b58e2304417787e96b940e39c6
```

PC110 changes live in `patches/`.
