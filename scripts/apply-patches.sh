#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$ROOT/seabios.version"

SRC="$("$ROOT/scripts/fetch-seabios.sh")"
git -C "$SRC" reset --hard "$SEABIOS_COMMIT" >&2
git -C "$SRC" clean -fdx >&2

for patch in "$ROOT"/patches/*.patch; do
    [[ -e "$patch" ]] || continue
    echo "Applying $(basename "$patch")" >&2
    git -C "$SRC" apply "$patch" >&2
done

printf '%s\n' "$SRC"
