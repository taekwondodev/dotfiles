#!/usr/bin/env python3
"""Native bundle assembly with fake inputs; no Hermes/Electron/signing."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HermesDesktop(unittest.TestCase):
    def test_bundle_identity_owned_runtime_and_preserved_inputs(self):
        with tempfile.TemporaryDirectory(prefix="desktop fixture ") as directory:
            root = Path(directory)
            electron = root / "Electron.app"
            for suffix in (None, "", " (GPU)", " (Renderer)", " (Plugin)"):
                app = electron if suffix is None else electron / f"Contents/Frameworks/Electron Helper{suffix}.app"
                name = "Electron" if suffix is None else f"Electron Helper{suffix}"
                (app / "Contents/MacOS").mkdir(parents=True)
                (app / "Contents/Info.plist").write_bytes(plistlib.dumps({
                    "CFBundleExecutable": name, "CFBundleIdentifier": "com.github.Electron",
                    "CFBundleName": name, "CFBundleIconName": "Electron",
                    "LSMinimumSystemVersion": "12.0", "CFBundlePackageType": "APPL"
                }))
                (app / "Contents/MacOS" / name).write_bytes(b"fake native executable: never run")
            (electron / "Contents/Resources").mkdir()
            desktop = root / "renderer"
            (desktop / "dist").mkdir(parents=True)
            (desktop / "package.json").write_text(json.dumps({"name": "hermes-desktop", "main": "dist/electron-main.mjs", "type": "module"}))
            (desktop / "install-stamp.json").write_text('{"distribution":"nix","updateMechanism":"external"}')
            (desktop / "dist/electron-preload.js").write_text("// fake preload\n")
            # The imported fixture only reports its launch contract, then fails.
            (desktop / "dist/electron-main.mjs").write_text("""
console.log(JSON.stringify({
  cli: process.env.HERMES_DESKTOP_HERMES, lazy: process.env.HERMES_DISABLE_LAZY_INSTALLS,
  dev: process.env.ELECTRON_IS_DEV, home: process.env.HOME, hermesHome: process.env.HERMES_HOME,
  cwd: process.cwd(), args: process.argv.slice(2)
}));
process.exitCode = 42;
""")
            source = root / "source"
            assets = source / "apps/desktop/assets"
            assets.mkdir(parents=True)
            (source / "apps/desktop/public").mkdir()
            (assets / "icon.icns").write_bytes(b"fixture icon")
            (source / "LICENSE").write_text("fixture license")
            identity = root / "identity.json"
            identity.write_text(json.dumps({
                "appId": "com.nousresearch.hermes", "productName": "Hermes", "executableName": "Hermes",
                "protocols": [{"name": "Hermes Protocol", "schemes": ["hermes"]}],
                "mac": {"category": "public.app-category.developer-tools", "extendInfo": {
                    "NSMicrophoneUsageDescription": "Hermes uses the microphone for voice input and voice conversations.",
                    "LSRequiresNativeExecution": True}}
            }))
            # Nix inputs are read-only. Copying must not make them writable.
            for path in [electron, *electron.rglob("*")]:
                path.chmod(path.stat().st_mode & ~0o222)
            before = {p: (hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mode)
                      for p in root.rglob("*") if p.is_file()}
            app = root / "output/Hermes.app"
            cli = root / "owned runtime/bin/hermes"
            command = ["python3", "-B", str(ROOT / "nix/hermes-desktop-bundle.py"),
                       str(electron), str(desktop), str(source), str(identity), str(cli), "0.22.2", str(app)]
            subprocess.run(command, check=True, capture_output=True)
            info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
            self.assertEqual(info["CFBundleIdentifier"], "com.nousresearch.hermes")
            self.assertEqual(info["CFBundleExecutable"], "Hermes")
            self.assertEqual(info["CFBundleShortVersionString"], "0.22.2")
            self.assertEqual(info["LSMinimumSystemVersion"], "12.0")
            self.assertNotIn("CFBundleIconName", info)
            self.assertEqual(info["NSMicrophoneUsageDescription"], "Hermes uses the microphone for voice input and voice conversations.")
            self.assertEqual(info["CFBundleURLTypes"], [{"CFBundleURLName": "Hermes Protocol", "CFBundleURLSchemes": ["hermes"], "CFBundleTypeRole": "Editor"}])
            for name, bundle_id in {
                "Hermes Helper": "com.nousresearch.hermes.helper",
                "Hermes Helper (GPU)": "com.nousresearch.hermes.helper.GPU",
                "Hermes Helper (Renderer)": "com.nousresearch.hermes.helper.Renderer",
                "Hermes Helper (Plugin)": "com.nousresearch.hermes.helper.Plugin",
            }.items():
                helper = app / f"Contents/Frameworks/{name}.app/Contents"
                self.assertEqual(plistlib.loads((helper / "Info.plist").read_bytes())["CFBundleIdentifier"], bundle_id)
                self.assertTrue((helper / "MacOS" / name).is_file())
            app_source = app / "Contents/Resources/app"
            self.assertTrue((app_source / "dist/electron-preload.js").is_file())
            self.assertEqual((app / "Contents/Resources/icon.icns").read_bytes(), b"fixture icon")
            self.assertEqual((app_source / "assets/icon.icns").read_bytes(), b"fixture icon")
            for path in app.rglob("*"):
                if path.is_symlink():
                    self.assertTrue(path.resolve().is_relative_to(app.resolve()), str(path))
            manifest = json.loads((app_source / "package.json").read_text())
            self.assertEqual(manifest["name"], "Hermes")
            env = {**os.environ, "HOME": str(root / "home"), "HERMES_HOME": str(root / "custom hermes"),
                   "HERMES_DESKTOP_HERMES": "/wrong", "HERMES_DISABLE_LAZY_INSTALLS": "0", "ELECTRON_IS_DEV": "1"}
            result = subprocess.run(["node", str(app_source / manifest["main"]), "hermes://profile/apple-dev", "a b", ""],
                                    cwd=root, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 42, result.stderr)
            self.assertEqual(json.loads(result.stdout), {"cli": str(cli), "lazy": "1", "dev": "0", "home": env["HOME"],
                "hermesHome": env["HERMES_HOME"], "cwd": str(root.resolve()), "args": ["hermes://profile/apple-dev", "a b", ""]})
            self.assertNotEqual(subprocess.run(command, capture_output=True).returncode, 0)
            self.assertEqual(before, {p: (hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mode) for p in before})


if __name__ == "__main__":
    unittest.main()
