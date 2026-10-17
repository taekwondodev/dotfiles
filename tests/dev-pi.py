"""Metadata-only resolution and launcher boundaries; never execute dev or Pi."""
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class DevPiPackaging(unittest.TestCase):
    def test_launchers_select_owned_runtime_preserve_arguments_and_writable_paths(self):
        with tempfile.TemporaryDirectory(prefix="dev pi ") as directory:
            root = Path(directory)
            node = root / "node/bin/node"
            node.parent.mkdir(parents=True)
            node.write_text("#!/bin/bash\nset -eu\nprintf '%s\\n' \"$PI_PACKAGE_DIR\" \"$PI_SKIP_VERSION_CHECK\" \"${DEV_PI_RELEASE-}\" \"${DEV_PROFILES-}\" \"${DEV_DATA_HOME-}\" \"$@\"\n")
            node.chmod(0o755)
            env = {"PATH": "/usr/bin:/bin", "HOME": str(root / "home with spaces")}
            args = ["--cwd", "a path with spaces", "$(touch not-executed)", ""]
            for name, entry in [("dev", "src/launcher.ts"), ("pi", "node_modules/@earendil-works/pi-coding-agent/dist/cli.js")]:
                launcher = (REPO / f"nix/{name}-launcher.sh").read_text()
                for key in ["dev", "pi", "node"]:
                    launcher = launcher.replace(f"@{key}@", str(root / key))
                script = root / name / "launcher"
                script.parent.mkdir(exist_ok=True)
                script.write_text(launcher)
                result = subprocess.run(["/bin/bash", str(script), *args], env=env, cwd=root, text=True, capture_output=True, check=True)
                values = result.stdout.splitlines()
                self.assertEqual(values[:2], [str(root / "pi/lib/pi/node_modules/@earendil-works/pi-coding-agent"), "1"])
                self.assertEqual(values[5:], [str(root / name / "lib" / name / entry), *args])
                self.assertFalse((root / "not-executed").exists())
                if name == "dev":
                    self.assertEqual(values[2:5], [str(root / "pi/lib/pi"), env["HOME"] + "/.local/share/dev/profiles", env["HOME"] + "/Library/Application Support/dev/data"])
                    override = dict(env, DEV_PROFILES=str(root / "custom profiles"), DEV_DATA_HOME=str(root / "custom data"), DEV_PI_RELEASE="unrelated-install")
                    overridden = subprocess.run(["/bin/bash", str(script)], env=override, cwd=root, text=True, capture_output=True, check=True).stdout.splitlines()
                    self.assertEqual(overridden[2:5], [str(root / "pi/lib/pi"), override["DEV_PROFILES"], override["DEV_DATA_HOME"]])
            self.assertFalse((root / "home with spaces").exists())

    def test_release_resolver_copies_metadata_only_and_propagates_failure(self):
        with tempfile.TemporaryDirectory(prefix="pi metadata ") as directory:
            root = Path(directory)
            binaries = root / "bin"
            binaries.mkdir()
            curl = binaries / "curl"
            curl.write_text("#!/bin/bash\nset -eu\n[[ $1 == --disable && $2 == --proto && $3 == '=https' && ${10} == -o ]]\ncase $9 in\n  https://pi.dev/api/installer/releases/1.3.0/package*json) cp \"$FIXTURE/${9##*/}\" \"${11}\" ;;\n  https://registry.npmjs.org/@example/runtime/1.3.0) cp \"$FIXTURE/registry.json\" \"${11}\" ;;\n  *) exit 99 ;;\nesac\n")
            curl.chmod(0o755)
            env = {"PATH": str(binaries) + ":/usr/bin:/bin", "HOME": str(root / "unused-home"), "FIXTURE": str(root)}
            (root / "package.json").write_text('{"version":"1.3.0"}\n')
            lock = '{"packages":{"node_modules/@example/runtime":{"version":"1.3.0","resolved":"https://registry.npmjs.org/@example/runtime/-/runtime-1.3.0.tgz"}}}\n'
            (root / "package-lock.json").write_text(lock)
            metadata = {"version": "1.3.0", "dist": {"tarball": "https://registry.npmjs.org/@example/runtime/-/runtime-1.3.0.tgz", "integrity": "sha512-Zml4dHVyZQ=="}}
            (root / "registry.json").write_text(json.dumps(metadata))
            command = ["/bin/bash", str(REPO / "nix/resolve-pi-release.sh")]
            work = root / "resolved"
            subprocess.run([*command, "1.3.0", str(work)], env=env, check=True)
            self.assertEqual(sorted(p.name for p in work.iterdir()), ["package-lock.json", "package.json", "source-integrity.json"])
            self.assertEqual((work / "package-lock.json").read_text(), lock)
            self.assertEqual(json.loads((work / "source-integrity.json").read_text()), {"node_modules/@example/runtime": "sha512-Zml4dHVyZQ=="})
            metadata["dist"]["tarball"] = "https://unrelated.invalid/runtime.tgz"
            (root / "registry.json").write_text(json.dumps(metadata))
            self.assertNotEqual(subprocess.run([*command, "1.3.0", str(root / "mismatch")], env=env, capture_output=True).returncode, 0)
            # Every registry predicate must hold; none may degrade into a missing hash.
            valid = {"version": "1.3.0", "dist": {"tarball": "https://registry.npmjs.org/@example/runtime/-/runtime-1.3.0.tgz", "integrity": "sha512-Zml4dHVyZQ=="}}
            for case, changed in {
                "version": {**valid, "version": "1.3.1"},
                "absent": {**valid, "dist": {"tarball": valid["dist"]["tarball"], "shasum": "abc"}},
                "sha1": {**valid, "dist": {**valid["dist"], "integrity": "sha1-Zml4dHVyZQ=="}},
            }.items():
                (root / "registry.json").write_text(json.dumps(changed))
                target = root / f"registry-{case}"
                self.assertNotEqual(subprocess.run([*command, "1.3.0", str(target)], env=env, capture_output=True).returncode, 0, case)
                self.assertNotIn("node_modules/@example/runtime", (target / "source-integrity.json").read_text(), case)
            (root / "registry.json").write_text(json.dumps(valid))
            (root / "package-lock.json").write_text(lock.replace('@example/runtime"', '@example/bad name"'))
            self.assertNotEqual(subprocess.run([*command, "1.3.0", str(root / "bad-name")], env=env, capture_output=True).returncode, 0)
            (root / "package-lock.json").write_text(lock)
            (root / "registry.json").write_text(json.dumps(metadata))
            self.assertNotEqual(subprocess.run([*command, "1.3.0", str(work)], env=env, capture_output=True).returncode, 0)
            invalid = root / "invalid"
            self.assertNotEqual(subprocess.run([*command, "../unexpected", str(invalid)], env=env, capture_output=True).returncode, 0)
            self.assertFalse(invalid.exists())
            (root / "package-lock.json").write_text("invalid json")
            self.assertNotEqual(subprocess.run([*command, "1.3.0", str(root / "malformed")], env=env, capture_output=True).returncode, 0)
            curl.write_text("#!/bin/sh\nexit 42\n")
            self.assertEqual(subprocess.run([*command, "1.3.0", str(root / "failed")], env=env, capture_output=True).returncode, 42)
            self.assertFalse((root / "unused-home").exists())


if __name__ == "__main__":
    unittest.main()
