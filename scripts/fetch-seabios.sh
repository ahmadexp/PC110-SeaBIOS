#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/seabios.version"

SRC="$ROOT/build/seabios"
mkdir -p "$ROOT/build"

if [[ ! -d "$SRC/.git" ]]; then
    git clone "$SEABIOS_REPO" "$SRC" >&2
fi

git -C "$SRC" fetch --tags origin "$SEABIOS_TAG" >&2
if ! git -C "$SRC" rev-parse --verify "$SEABIOS_COMMIT^{commit}" >/dev/null 2>&1; then
    git -C "$SRC" fetch origin "$SEABIOS_COMMIT" >&2
fi
git -C "$SRC" checkout --detach "$SEABIOS_COMMIT" >&2

printf '%s\n' "$SRC"
