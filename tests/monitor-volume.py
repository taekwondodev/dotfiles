#!/usr/bin/env python3
"""Exercise bundle assembly with fake products/converters; never run the app."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class MonitorVolume(unittest.TestCase):
    def test_native_bundle_identity_artwork_and_safe_output(self):
        with tempfile.TemporaryDirectory(prefix="monitor volume ' fixture ") as directory:
            root = Path(directory).resolve()
            source, products, tools = root / "source", root / "products", root / "tools"
            artwork = source / "Resources/Media.xcassets/AppIcon.appiconset/original artwork.png"
            artwork.parent.mkdir(parents=True)
            artwork.write_bytes(b"fixture artwork: never decoded")
            products.mkdir(); tools.mkdir()
            binary = products / "MonitorVolume"
            binary.write_bytes(b"fixture executable: never run"); binary.chmod(0o755)
            identity = {"CFBundleName": "Monitor Volume", "CFBundleIdentifier": "dev.taekwondodev.MonitorVolume",
                        "CFBundleExecutable": "MonitorVolume", "CFBundleIconFile": "AppIcon", "LSUIElement": True,
                        "LSMinimumSystemVersion": "15.0", "NSBonjourServices": ["_monitorvol-v1._tcp"],
                        "NSLocalNetworkUsageDescription": "fixture local network permission description"}
            (source / "Resources/Info.plist").write_bytes(plistlib.dumps(identity))
            for notice in ("LICENSE", "THIRD_PARTY_NOTICES.md"):
                (source / notice).write_text("fixture " + notice)
            fake = f'#!{sys.executable}\n' + '''import json, os, pathlib, sys
args = sys.argv[1:]
with open(os.environ["CALLS"], "a") as log:
    log.write(json.dumps([pathlib.Path(sys.argv[0]).name, *args]) + "\\n")
if args[0] == "identify":
    print(os.environ.get("IMAGE_SIZE", "1024x1024"))
elif pathlib.Path(sys.argv[0]).name == "magick":
    pathlib.Path(args[-1].removeprefix("PNG32:")).write_bytes(b"fixture resized image")
else:
    if os.environ.get("FAIL_CONVERTER"):
        sys.exit(42)
    pathlib.Path(args[0]).write_bytes(b"fixture ICNS: not a rendering test")
'''
            for command in ("magick", "png2icns"):
                (tools / command).write_text(fake); (tools / command).chmod(0o755)
            inputs = {p: hashlib.sha256(p.read_bytes()).hexdigest() for base in (source, products) for p in base.rglob('*') if p.is_file()}
            app = root / "Applications/Monitor Volume.app"
            env = {**os.environ, "PATH": str(tools) + os.pathsep + os.environ["PATH"], "CALLS": str(root / "calls"), "TMPDIR": str(root)}
            def assemble(target, **extra):
                return subprocess.run(["bash", str(ROOT / "nix/monitor-volume-bundle.sh"), str(products), str(source), str(target)],
                                      env={**env, **extra}, capture_output=True, text=True)
            result = assemble(app)
            self.assertEqual(result.returncode, 0, result.stderr)
            contents = app / "Contents"
            self.assertEqual(plistlib.loads((contents / "Info.plist").read_bytes()), identity)
            self.assertEqual((contents / "MacOS/MonitorVolume").read_bytes(), binary.read_bytes())
            self.assertEqual((contents / "MacOS/MonitorVolume").stat().st_mode & 0o777, 0o755)
            for notice in ("LICENSE", "THIRD_PARTY_NOTICES.md"):
                self.assertEqual((contents / "Resources" / notice).read_bytes(), (source / notice).read_bytes())
            self.assertEqual((contents / "Resources/AppIcon.icns").read_bytes(), b"fixture ICNS: not a rendering test")
            calls = [json.loads(line) for line in (root / "calls").read_text().splitlines()]
            resized = [call for call in calls if call[:2] == ["magick", str(artwork)]]
            self.assertEqual([call[3] for call in resized], [f"{n}x{n}" for n in (16, 32, 128, 256, 512, 1024)])
            self.assertEqual(len(calls[-1][2:]), 6)
            self.assertEqual(inputs, {p: hashlib.sha256(p.read_bytes()).hexdigest() for p in inputs})
            output = {p: p.read_bytes() for p in app.rglob("*") if p.is_file()}
            self.assertNotEqual(assemble(app).returncode, 0)
            link = root / "occupied.app"; link.symlink_to(app, target_is_directory=True)
            self.assertNotEqual(assemble(link).returncode, 0)
            self.assertEqual(output, {p: p.read_bytes() for p in output})
            self.assertEqual(assemble(root / "converter-fails.app", FAIL_CONVERTER="1").returncode, 42)
            self.assertNotEqual(assemble(root / "wrong-size.app", IMAGE_SIZE="512x512").returncode, 0)
            duplicate = artwork.with_name("other.png"); duplicate.write_bytes(b"other")
            self.assertNotEqual(assemble(root / "ambiguous.app").returncode, 0)
            duplicate.unlink(); artwork.unlink()
            self.assertNotEqual(assemble(root / "missing.app").returncode, 0)


if __name__ == "__main__":
    unittest.main()
