#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIOS="${1:-$ROOT/out/pc110-seabios-debug.bin}"
QEMU="${QEMU:-qemu-system-i386}"
QEMU_MACHINE="${QEMU_MACHINE:-pc}"
SMOKE_IMG="${SMOKE_IMG:-$ROOT/build/smoke/pc110-smoke.img}"
FLOPPY_TYPE_CFG="${FLOPPY_TYPE_CFG:-$ROOT/build/smoke/floppy0.type}"
SERIAL_LOG="${SERIAL_LOG:-$ROOT/build/smoke/serial.log}"
QEMU_LOG="${QEMU_LOG:-$ROOT/build/smoke/qemu.log}"

[[ -f "$BIOS" ]] || {
    echo "error: BIOS image not found: $BIOS" >&2
    exit 1
}
command -v "$QEMU" >/dev/null || {
    echo "error: qemu-system-i386 not found" >&2
    exit 1
}

"$ROOT/scripts/make-smoke-floppy.sh" "$SMOKE_IMG" >/dev/null
mkdir -p "$(dirname "$FLOPPY_TYPE_CFG")"
printf '\004' > "$FLOPPY_TYPE_CFG"
rm -f "$SERIAL_LOG" "$QEMU_LOG"

set +e
timeout 30s "$QEMU" \
    -M "$QEMU_MACHINE" \
    -m 20M \
    -cpu 486 \
    -bios "$BIOS" \
    -drive "file=$SMOKE_IMG,format=raw,if=floppy,index=0" \
    -boot a \
    -fw_cfg "name=etc/floppy0,file=$FLOPPY_TYPE_CFG" \
    -display none \
    -serial "file:$SERIAL_LOG" \
    -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
    -no-reboot \
    -no-shutdown \
    >"$QEMU_LOG" 2>&1
rc=$?
set -e

if [[ "$rc" != "33" ]]; then
    echo "error: QEMU smoke test exited with $rc, expected 33" >&2
    sed -n '1,160p' "$QEMU_LOG" >&2 || true
    tail -n 240 "$SERIAL_LOG" >&2 || true
    exit 1
fi

if ! grep -q "PC110 BIOS BOOT OK" "$SERIAL_LOG"; then
    echo "error: smoke-test boot marker not found on serial output" >&2
    tail -n 240 "$SERIAL_LOG" >&2 || true
    exit 1
fi

echo "QEMU smoke test passed"
