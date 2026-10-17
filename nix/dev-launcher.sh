#!/bin/bash
set -euo pipefail
export DEV_PI_RELEASE="@pi@/lib/pi"
export PI_PACKAGE_DIR="$DEV_PI_RELEASE/node_modules/@earendil-works/pi-coding-agent"
export PI_SKIP_VERSION_CHECK=1
export DEV_PROFILES="${DEV_PROFILES:-$HOME/.local/share/dev/profiles}"
export DEV_DATA_HOME="${DEV_DATA_HOME:-$HOME/Library/Application Support/dev/data}"
export PATH="@node@/bin:$PATH"
exec "@node@/bin/node" "@dev@/lib/dev/src/launcher.ts" "$@"
