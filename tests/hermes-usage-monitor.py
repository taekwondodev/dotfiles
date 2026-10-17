#!/usr/bin/env python3
"""Exercise bundle/bridge adaptation with fake inputs, never Hermes or Swift."""
import hashlib
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HermesUsageMonitor(unittest.TestCase):
    def test_native_bundle_and_canonical_owned_bridge(self):
        with tempfile.TemporaryDirectory(prefix="usage monitor ' fixture ") as directory:
            root = Path(directory).resolve()
            source, products = root / "source", root / "products"
            (source / "scripts").mkdir(parents=True)
            (products / "HermesUsageMonitor_HermesUsageMonitorApp.bundle").mkdir(parents=True)
            (products / "HermesUsageMonitor_HermesUsageMonitorApp.bundle/resource").write_bytes(b"resource")
            (products / "HermesUsageMonitor").write_bytes(b"native executable: never run")
            (products / "HermesUsageMonitor").chmod(0o755)
            identity = {"CFBundleIdentifier": "com.taekwondodev.HermesUsageMonitor", "CFBundleExecutable": "HermesUsageMonitor",
                        "CFBundleVersion": "1", "LSUIElement": True, "LSMinimumSystemVersion": "26.0", "CFBundleIconName": "AppIcon"}
            (source / "scripts/Info.plist").write_bytes(plistlib.dumps(identity))
            (source / "scripts/hermes_usage_bridge.py").write_text("# fixture bridge: never imported\n")
            (source / "LICENSE").write_text("fixture license")
            # Match uv2nix: an environment can link code from another package.
            package = root / "package/site-packages"
            (package / "agent").mkdir(parents=True)
            (package / "agent/account_usage.py").write_text("# fixture API: never imported\n")
            site = root / "venv/site-packages"
            site.mkdir(parents=True)
            (site / "agent").symlink_to(package / "agent", target_is_directory=True)
            python = root / "venv/python"
            python.write_text('#!/bin/sh\nprintf "%s\\0" "$HERMES_HOME" "$PYTHONDONTWRITEBYTECODE" "$HERMES_DISABLE_LAZY_INSTALLS" "$@"\nexit 42\n')
            python.chmod(0o755)
            before = {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in root.rglob("*") if p.is_file()}
            app = root / "output/HermesUsageMonitor.app"
            command = [sys.executable, "-B", str(ROOT / "nix/hermes-usage-monitor-bundle.py"),
                       str(products), str(source), str(python), str(site / "agent/account_usage.py"), str(app)]
            subprocess.run(command, check=True, capture_output=True)
            self.assertEqual(plistlib.loads((app / "Contents/Info.plist").read_bytes()), identity)
            self.assertEqual((app / "Contents/MacOS/HermesUsageMonitor").read_bytes(), b"native executable: never run")
            resources = app / "Contents/Resources"
            self.assertEqual((resources / "HermesUsageMonitor_HermesUsageMonitorApp.bundle/resource").read_bytes(), b"resource")
            self.assertEqual((resources / "hermes_usage_bridge.py").read_bytes(), (source / "scripts/hermes_usage_bridge.py").read_bytes())
            self.assertEqual((resources / "LICENSE").read_text(), "fixture license")
            self.assertFalse(any(p.is_symlink() for p in app.rglob("*")))
            env = {**os.environ, "HOME": str(root / "home"), "HERMES_HOME": str(root / "profile home"),
                   "HERMES_AGENT_ROOT": "/wrong", "HERMES_DISABLE_LAZY_INSTALLS": "0"}
            result = subprocess.run([str(app / "Contents/Helpers/hermes-usage-bridge"), "--json", "a b", ""], env=env, capture_output=True)
            self.assertEqual(result.returncode, 42, result.stderr)
            observed = result.stdout.decode().split("\0")
            self.assertEqual(observed[:3], [env["HERMES_HOME"], "1", "1"])
            self.assertEqual(Path(observed[3]).resolve(), resources / "hermes_usage_bridge.py")
            self.assertEqual(observed[4:], ["--hermes-root", str(package), "--json", "a b", "", ""])
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(before, {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in before})


if __name__ == "__main__":
    unittest.main()
