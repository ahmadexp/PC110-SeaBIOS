#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/build/smoke/pc110-smoke.img}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/pc110-smoke.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

command -v nasm >/dev/null || {
    echo "error: nasm is required to build the smoke-test boot sector" >&2
    exit 1
}

mkdir -p "$(dirname "$OUT")"
cat > "$WORK/smoke.asm" <<'ASM'
BITS 16
ORG 0x7c00

SERIAL      equ 0x3f8
DEBUG_EXIT  equ 0x0f4

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti

    call serial_init
    mov si, msg
.put:
    lodsb
    test al, al
    jz .done
    call serial_putc
    jmp .put
.done:
    mov ax, 0x0010
    mov dx, DEBUG_EXIT
    out dx, ax
.halt:
    hlt
    jmp .halt

serial_init:
    mov dx, SERIAL + 1
    xor al, al
    out dx, al
    mov dx, SERIAL + 3
    mov al, 0x80
    out dx, al
    mov dx, SERIAL
    mov al, 0x01
    out dx, al
    mov dx, SERIAL + 1
    xor al, al
    out dx, al
    mov dx, SERIAL + 3
    mov al, 0x03
    out dx, al
    mov dx, SERIAL + 2
    mov al, 0xc7
    out dx, al
    mov dx, SERIAL + 4
    mov al, 0x0b
    out dx, al
    ret

serial_putc:
    push ax
.wait:
    mov dx, SERIAL + 5
    in al, dx
    test al, 0x20
    jz .wait
    pop ax
    mov dx, SERIAL
    out dx, al
    ret

msg db "PC110 BIOS BOOT OK", 13, 10, 0

times 510-($-$$) db 0
dw 0xaa55
ASM

nasm -f bin -o "$WORK/smoke.bin" "$WORK/smoke.asm"
python3 - "$WORK/smoke.bin" "$OUT" <<'PY'
import sys
boot = open(sys.argv[1], "rb").read()
img = bytearray(1474560)
img[:len(boot)] = boot
open(sys.argv[2], "wb").write(img)
PY
echo "$OUT"

