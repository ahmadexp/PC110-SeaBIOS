#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${CONTAINER:-0}" == "1" ]]; then
    runtime="${CONTAINER_RUNTIME:-}"
    if [[ -z "$runtime" ]]; then
        if command -v docker >/dev/null 2>&1; then
            runtime=docker
        elif command -v podman >/dev/null 2>&1; then
            runtime=podman
        else
            echo "error: CONTAINER=1 requested but docker/podman was not found" >&2
            exit 1
        fi
    fi
    image="${CONTAINER_IMAGE:-debian:bookworm}"
    exec "$runtime" run --rm -v "$ROOT:/work" -w /work "$image" bash -lc \
        'apt-get update &&
         DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential ca-certificates git gcc-multilib iasl python3 python-is-python3 &&
         CONTAINER=0 ./scripts/build.sh'
fi

SRC="$("$ROOT/scripts/apply-patches.sh")"
CONFIG_FILE="${CONFIG_FILE:-$ROOT/configs/pc110_defconfig}"
CONFIG_OVERLAY="${CONFIG_OVERLAY:-}"
OUT_NAME="${OUT_NAME:-pc110-seabios}"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "error: config file not found: $CONFIG_FILE" >&2
    exit 1
fi

cp "$CONFIG_FILE" "$SRC/.config"
if [[ -n "$CONFIG_OVERLAY" ]]; then
    if [[ ! -f "$CONFIG_OVERLAY" ]]; then
        echo "error: config overlay not found: $CONFIG_OVERLAY" >&2
        exit 1
    fi
    cat "$CONFIG_OVERLAY" >> "$SRC/.config"
fi

if [[ -n "${PC110_BIOS_DUMP:-}" ]]; then
    python3 "$ROOT/scripts/extract-pc110-assets.py" \
        "$PC110_BIOS_DUMP" "$SRC/src/fw/pc110_easysetup_blob.c"
fi

make_args=(PYTHON="${PYTHON:-python3}")
if [[ -n "${CROSS_PREFIX:-}" ]]; then
    make_args+=(CROSS_PREFIX="$CROSS_PREFIX")
fi

jobs="${JOBS:-}"
if [[ -z "$jobs" ]]; then
    jobs="$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)"
fi

make -C "$SRC" "${make_args[@]}" olddefconfig
make -C "$SRC" "${make_args[@]}" -j"$jobs"

mkdir -p "$ROOT/out"
cp "$SRC/out/bios.bin" "$ROOT/out/$OUT_NAME.bin"
ls -lh "$ROOT/out/$OUT_NAME.bin"
