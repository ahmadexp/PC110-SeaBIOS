# Roadmap

## Phase 0: Buildable PC110 SeaBIOS

- Keep the firmware as a small patch stack on upstream SeaBIOS.
- Build a `CONFIG_PC110` target in CI.
- Provide PC110 memory sizing and private BIOS-call compatibility.
- Add optional Easy-Setup bundling from a user-supplied IBM dump.

## Phase 1: First Hardware POST

- Boot with serial/debug visibility where possible.
- Confirm reset vector, ROM mapping, RAM sizing, IVT/BDA setup, PIT/PIC/RTC,
  keyboard controller, and INT 13h CF boot.
- Capture logs from SCAMP, power MCU, PCIC, and CMOS probes.
- Keep expanding the PC110 POST stage as hardware traces recover safe register
  values for `0x8b`, `0x98`, `0xf1`, and SCAMP indexed writes.

## Phase 2: IBM BIOS Parity

- Map CMOS checksums and boot-order semantics.
- Replace default digitizer selector with live CMOS-backed resource selection.
- Implement PC110-specific APM battery and power-state reporting.
- Add safe power-off/suspend paths through the power MCU.
- Confirm PCMCIA socket/card detection and resource windows.
- Confirm CHIPS 65535 VGA BIOS interaction and LCD/CRT output control.

## Phase 3: Easy-Setup Integration

- Run IBM Easy-Setup from the SeaBIOS F1 path with bundled legal payload.
- Provide the BIOS services Easy-Setup expects for settings, diagnostics,
  reboot, and power operations.
- Validate Date/Time, Password, Start up, Test, Restart, and Config behavior
  against the original BIOS.

## Phase 4: Flash Candidate

- Produce a 256 KiB image that fits the PC110 flash device.
- Verify image checksum and reset-vector layout.
- Test on sacrificial hardware with external flash recovery.
- Document flashing and rollback.
