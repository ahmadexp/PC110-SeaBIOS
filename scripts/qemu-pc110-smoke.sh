#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIOS="${1:-$ROOT/out/pc110-seabios-smoke.bin}"
PC110_QEMU_ROOT="${PC110_QEMU_ROOT:-$HOME/git/pc110-qemu}"
QEMU="${QEMU:-$PC110_QEMU_ROOT/qemu-src/build/qemu-system-i386}"
QEMU_MACHINE="${QEMU_MACHINE:-pc}"
QEMU_TIMEOUT="${QEMU_TIMEOUT:-25s}"
SMOKE_IMG="${SMOKE_IMG:-$ROOT/build/smoke/pc110-smoke.img}"
FLOPPY_TYPE_CFG="${FLOPPY_TYPE_CFG:-$ROOT/build/smoke/floppy0.type}"
LOG_ROOT="${LOG_ROOT:-$ROOT/build/smoke/pc110-qemu}"
LOGDIR="${LOGDIR:-$LOG_ROOT/$(date +%Y%m%d-%H%M%S)}"
SERIAL_LOG="$LOGDIR/serial.log"
QEMU_LOG="$LOGDIR/qemu.log"

[[ -f "$BIOS" ]] || {
    echo "error: BIOS image not found: $BIOS" >&2
    exit 1
}
case "$(basename "$BIOS")" in
    *smoke*) ;;
    *)
        echo "warning: this harness is intended for pc110-seabios-smoke.bin" >&2
        echo "warning: release flash images usually omit QEMU-only shadow/debug paths" >&2
        ;;
esac
[[ -x "$QEMU" ]] || {
    echo "error: PC110 QEMU binary not executable: $QEMU" >&2
    echo "hint: set QEMU=/path/to/qemu-system-i386 or build $PC110_QEMU_ROOT" >&2
    exit 1
}
command -v timeout >/dev/null || {
    echo "error: timeout is required for the PC110-QEMU smoke harness" >&2
    exit 1
}

if ! "$QEMU" -device help 2>&1 | grep -q 'pc110-chipset'; then
    echo "error: QEMU does not provide the pc110-chipset device: $QEMU" >&2
    exit 1
fi

"$ROOT/scripts/make-smoke-floppy.sh" "$SMOKE_IMG" >/dev/null
mkdir -p "$(dirname "$FLOPPY_TYPE_CFG")" "$LOGDIR"
printf '\004' > "$FLOPPY_TYPE_CFG"

set +e
timeout "$QEMU_TIMEOUT" "$QEMU" \
    -M "$QEMU_MACHINE" \
    -m 20M \
    -cpu 486 \
    -bios "$BIOS" \
    -drive "file=$SMOKE_IMG,format=raw,if=floppy,index=0" \
    -boot a \
    -fw_cfg "name=etc/floppy0,file=$FLOPPY_TYPE_CFG" \
    -device pc110-chipset \
    -display none \
    -serial "file:$SERIAL_LOG" \
    -device isa-debug-exit,iobase=0xf4,iosize=0x04 \
    -no-reboot \
    -no-shutdown \
    >"$QEMU_LOG" 2>&1
rc=$?
set -e

if ! grep -q "PC110 POST complete" "$SERIAL_LOG"; then
    echo "error: PC110 POST completion marker not found on serial output" >&2
    sed -n '1,160p' "$QEMU_LOG" >&2 || true
    tail -n 240 "$SERIAL_LOG" >&2 || true
    exit 1
fi

if ! grep -q "PC110 BIOS BOOT OK" "$SERIAL_LOG"; then
    echo "error: smoke-test boot marker not found on serial output" >&2
    sed -n '1,160p' "$QEMU_LOG" >&2 || true
    tail -n 240 "$SERIAL_LOG" >&2 || true
    exit 1
fi

if [[ "$rc" != "33" && "$rc" != "124" ]]; then
    echo "error: QEMU exited with $rc after producing success markers" >&2
    sed -n '1,160p' "$QEMU_LOG" >&2 || true
    tail -n 240 "$SERIAL_LOG" >&2 || true
    exit 1
fi

echo "PC110-QEMU smoke test passed"
echo "  qemu: $QEMU"
echo "  bios: $BIOS"
echo "  logs: $LOGDIR"
if [[ "$rc" == "124" ]]; then
    echo "  note: QEMU timed out after success markers; isa-debug-exit did not terminate this build"
fi
