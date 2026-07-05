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
    call pc110_int15_smoke
    jnc .ok
    mov si, fail_msg
    call serial_puts
    mov ax, 0x0011
    jmp .exit
.ok:
    mov si, msg
    call serial_puts
    mov ax, 0x0010
.exit:
    mov dx, DEBUG_EXIT
    out dx, ax
.halt:
    hlt
    jmp .halt

pc110_int15_smoke:
    mov ax, 0x5380
    mov bx, 0x7f00
    int 0x15
    jc .fail
    cmp bh, 'S'
    jne .fail
    cmp bl, 'L'
    jne .fail
    cmp cl, 'O'
    jne .fail

    mov ax, 0x5380
    mov bx, 0x8300
    int 0x15
    jc .fail
    cmp cl, 0x00
    jne .fail

    mov ax, 0x1234
    mov es, ax
    mov ax, 0x5000
    mov bx, 0x0100
    xor bp, bp
    int 0x15
    jnc .fail
    cmp ah, 0x86
    jne .fail
    cmp bx, 0x0000
    jne .fail
    mov ax, es
    cmp ax, 0x0000
    jne .fail

    mov ax, 0x5000
    xor bx, bx
    mov bp, 0x0001
    int 0x15
    jc .fail

    xor ax, ax
    mov ds, ax
    mov es, ax
    clc
    ret
.fail:
    xor ax, ax
    mov ds, ax
    mov es, ax
    stc
    ret

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

serial_puts:
    lodsb
    test al, al
    jz .done
    call serial_putc
    jmp serial_puts
.done:
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
fail_msg db "PC110 BIOS INT15 FAIL", 13, 10, 0

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
