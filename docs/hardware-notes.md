# PC110 Hardware Notes

These are the hardware facts this BIOS target currently uses.

| Area | Access | Current use |
| --- | --- | --- |
| System controller | VL82C420 / SCAMP IV | target chipset |
| SCAMP config gate | `0x22/0x23` | unlock/relock for indexed reads |
| SCAMP indexed config | `0x74` index, `0x76` data | probe signature at `0x7a/0x7b` (`53 4c`, "SL") |
| RAM size | CMOS `0x30/0x31` | extended KB above 1 MiB |
| Boot order | CMOS `0x1d/0x1e` | logged, not yet enforced |
| Keyboard click | CMOS `0x44` bitfield | logged |
| LCD status panel | CMOS `0x70` | logged |
| Power settings | CMOS `0x72` bitfield | logged |
| Power MCU | `0xec` index, `0xed` data | probe register `0x00` |
| PCMCIA controller | `0x3e0` index, `0x3e1` data | probe chip ID, expected `0x83` on PC110 |
| Digitizer resource call | INT 15h `AX=5380h, BX=8300h` | currently returns default selector `CL=0` |
| Private event poll | INT 15h `AX=5000h, BH=01h, BP=0000h` | no-event status `AH=86h`, `CF=1`, `ES:BX=0000:0000` |
| PC110 identify call | INT 15h `AX=5380h, BH=7fh` | returns `BH='S', BL='L', CL='O'` |
| System configuration table | INT 15h `AH=C0h` | model `FCh`, submodel `01h`, PC110 feature bytes |
| Easy-Setup load address | physical `0x50000` | decompressed runtime target |
| Easy-Setup entry | `5000:0000` | entered after VGA mode `12h` |

The current target intentionally avoids write-heavy chipset initialization until
POST behavior is observed on real hardware or a PC110 emulator with enough
chipset coverage.
