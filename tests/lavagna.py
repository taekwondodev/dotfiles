#!/usr/bin/env python3
"""Test native assembly with inert products and converters, never Lavagna."""
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class Lavagna(unittest.TestCase):
    def test_notification_bundle_preserves_identity_and_refuses_occupied_output(self):
        with tempfile.TemporaryDirectory(prefix="lavagna ' fixture ") as directory:
            root = Path(directory).resolve()
            source, tools = root / "public source", root / "tools"
            notifier = source / "macos/notifier"
            notifier.mkdir(parents=True); tools.mkdir()
            binary = root / "compiled helper"
            binary.write_bytes(b"fixture executable: never run"); binary.chmod(0o755)
            identity = {"CFBundleIdentifier": "io.github.taekwondodev.lavagna", "CFBundleName": "Lavagna",
                        "CFBundleExecutable": "lavagna-notifier", "CFBundleIconFile": "AppIcon", "LSUIElement": True,
                        "LSMinimumSystemVersion": "13.0", "NSAppleEventsUsageDescription": "fixture Chrome consent"}
            (notifier / "Info.plist").write_bytes(plistlib.dumps(identity))
            (notifier / "AppIcon.png").write_bytes(b"fixture original artwork")
            (source / "LICENSE").write_text("fixture MIT license")
            fake = f'#!{sys.executable}\n' + '''import json, os, pathlib, sys
args = sys.argv[1:]
with open(os.environ["CALLS"], "a") as log:
    log.write(json.dumps([pathlib.Path(sys.argv[0]).name, *args]) + "\\n")
if args[0] == "identify":
    print("1024x1024")
elif pathlib.Path(sys.argv[0]).name == "magick":
    pathlib.Path(args[-1].removeprefix("PNG32:")).write_bytes(b"fixture resized image")
else:
    if os.environ.get("FAIL_CONVERTER"):
        sys.exit(42)
    pathlib.Path(args[0]).write_bytes(b"fixture ICNS: not a rendering test")
'''
            for command in ("magick", "png2icns"):
                (tools / command).write_text(fake); (tools / command).chmod(0o755)
            env = {**os.environ, "PATH": str(tools) + os.pathsep + os.environ["PATH"], "CALLS": str(root / "calls"), "TMPDIR": str(root)}
            app = root / "package/Applications/Lavagna.app"
            def assemble(target, **extra):
                return subprocess.run(["bash", str(ROOT / "nix/lavagna-bundle.sh"), str(binary), str(source), str(target)],
                                      env={**env, **extra}, capture_output=True, text=True)
            inputs = {p: p.read_bytes() for p in source.rglob('*') if p.is_file()}
            result = assemble(app)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual((app / "Contents/Info.plist").read_bytes(), (notifier / "Info.plist").read_bytes())
            self.assertEqual((app / "Contents/MacOS/lavagna-notifier").read_bytes(), binary.read_bytes())
            self.assertEqual((app / "Contents/MacOS/lavagna-notifier").stat().st_mode & 0o777, 0o755)
            self.assertEqual((app / "Contents/Resources/LICENSE").read_bytes(), b"fixture MIT license")
            self.assertEqual((app / "Contents/Resources/AppIcon.icns").read_bytes(), b"fixture ICNS: not a rendering test")
            calls = [json.loads(line) for line in (root / "calls").read_text().splitlines()]
            resized = [c for c in calls if c[:2] == ["magick", str(notifier / "AppIcon.png")]]
            self.assertEqual([c[3] for c in resized], [f"{n}x{n}" for n in (16, 32, 128, 256, 512, 1024)])
            self.assertEqual(len(calls[-1][2:]), 6)
            output = {p: p.read_bytes() for p in app.rglob('*') if p.is_file()}
            self.assertNotEqual(assemble(app).returncode, 0)
            alias = root / "occupied.app"; alias.symlink_to(app, target_is_directory=True)
            self.assertNotEqual(assemble(alias).returncode, 0)
            self.assertEqual(output, {p: p.read_bytes() for p in output})
            self.assertEqual(inputs, {p: p.read_bytes() for p in inputs})
            self.assertEqual(assemble(root / "converter-fails.app", FAIL_CONVERTER="1").returncode, 42)


if __name__ == "__main__":
    unittest.main()
