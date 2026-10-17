#!/bin/bash
set -euo pipefail
export PI_PACKAGE_DIR="@pi@/lib/pi/node_modules/@earendil-works/pi-coding-agent"
export PI_SKIP_VERSION_CHECK=1
export PATH="@node@/bin:$PATH"
# Use the published unbundled entrypoint so the Nix ownership patch applies.
exec "@node@/bin/node" "$PI_PACKAGE_DIR/dist/cli.js" "$@"
