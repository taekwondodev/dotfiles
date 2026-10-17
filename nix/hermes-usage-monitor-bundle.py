#!/usr/bin/env python3
"""Assemble public/build inputs only; no app execution, signing or installation."""
from pathlib import Path
import shlex
import shutil
import sys


def assemble(products, source, python, account_usage, app):
    # uv2nix can symlink agent/ from a separate package. The bridge checks the
    # resolved module path, so a virtualenv's site-packages is not its true root.
    hermes_root = account_usage.resolve(strict=True).parents[1]
    app.mkdir(parents=True)  # Refuse an occupied output, including symlinks.
    contents = app / "Contents"
    for name in ("MacOS", "Resources", "Helpers"):
        (contents / name).mkdir(parents=True)
    shutil.copy2(products / "HermesUsageMonitor", contents / "MacOS/HermesUsageMonitor")
    shutil.copy2(source / "scripts/Info.plist", contents / "Info.plist")
    resources = contents / "Resources"
    shutil.copytree(products / "HermesUsageMonitor_HermesUsageMonitorApp.bundle",
                    resources / "HermesUsageMonitor_HermesUsageMonitorApp.bundle")
    shutil.copy2(source / "scripts/hermes_usage_bridge.py", resources / "hermes_usage_bridge.py")
    shutil.copy2(source / "LICENSE", resources / "LICENSE")
    helper = contents / "Helpers/hermes-usage-bridge"
    helper.write_text(
        '#!/bin/sh\nset -eu\n'
        'SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)\n'
        'export PYTHONDONTWRITEBYTECODE=1 HERMES_DISABLE_LAZY_INSTALLS=1\n'
        f'exec {shlex.quote(str(python))} "$SCRIPT_DIR/../Resources/hermes_usage_bridge.py" '
        f'--hermes-root {shlex.quote(str(hermes_root))} "$@"\n'
    )
    helper.chmod(0o755)


if __name__ == "__main__":
    assemble(*(Path(argument) for argument in sys.argv[1:]))
