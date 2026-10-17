"""Approved dependency-policy cases at the production classifier's JSON boundary."""
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("dependencies", Path(__file__).parents[1] / "nix/check-dependencies.py")
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class DependencyPolicy(unittest.TestCase):
    def test_transitive_jvm_is_skipped_without_excluding_syntax_tools(self):
        graph = {"version": 4, "derivations": {
            "aaa-tool.drv": {"name": "approved-tool", "inputs": {"drvs": {"bbb-lib.drv": {}}}},
            "bbb-lib.drv": {"name": "support-lib", "inputs": {"drvs": {"ccc-java.drv": {}}}},
            "ccc-java.drv": {"name": "openjdk-24", "inputs": {"drvs": {}}},
            "ddd-js.drv": {"name": "javascript-language-server", "inputs": {"drvs": {}}},
            "eee-parser.drv": {"name": "tree-sitter-java-0.23", "inputs": {"drvs": {}}},
        }}
        self.assertEqual(policy.classify({"tool": "/nix/store/aaa-tool.drv", "js": "/nix/store/ddd-js.drv",
                                          "parser": "/nix/store/eee-parser.drv"}, graph),
                         {"tool": "Forbidden Java/Maven/Android dependency: openjdk-24"})

    def test_incomplete_graph_refuses_instead_of_declaring_package_safe(self):
        with self.assertRaises(KeyError):
            policy.classify({"tool": "/nix/store/aaa-tool.drv"}, {
                "/nix/store/aaa-tool.drv": {"env": {"name": "tool"}, "inputDrvs": {"/nix/store/missing.drv": ["out"]}}
            })

    def test_android_tool_names_are_forbidden(self):
        for name in ("android-sdk", "android-platform-tools-35", "android-commandlinetools", "android-tools", "androidstudio"):
            self.assertTrue(policy.FORBIDDEN.search(name), name)
        self.assertFalse(policy.FORBIDDEN.search("tree-sitter-android-bp"))

    def test_cli_failure_exits_nonzero_without_a_skip_list(self):
        # The runner consumes stdout as the skip list; failures must not produce one.
        script = str(Path(__file__).parents[1] / "nix/check-dependencies.py")
        with tempfile.TemporaryDirectory() as directory:
            packages, graph = Path(directory, "packages.json"), Path(directory, "graph.json")
            packages.write_text(json.dumps({"tool": "/nix/store/aaa-tool.drv"}))
            graph.write_text(json.dumps({"/nix/store/aaa-tool.drv": {"inputDrvs": {"/nix/store/missing.drv": ["out"]}}}))
            for args in ([str(packages), str(graph)], ["--homebrew", str(packages)], []):
                result = subprocess.run([sys.executable, "-I", script, *args], capture_output=True, text=True)
                self.assertNotEqual(result.returncode, 0, args)
                self.assertEqual(result.stdout, "", args)
                self.assertIn("Cannot establish dependency safety", result.stderr, args)

    def test_legacy_nix_graph_has_the_same_policy(self):
        self.assertEqual(policy.classify({"tool": "/nix/store/aaa-tool.drv"}, {
            "/nix/store/aaa-tool.drv": {"env": {"name": "maven-3"}, "inputDrvs": {}}
        }), {"tool": "Forbidden Java/Maven/Android dependency: maven-3"})


class HomebrewPolicy(unittest.TestCase):
    def cask(self, name, dependencies=None, artifacts=None):
        return {"token": name, "depends_on": dependencies or {}, "artifacts": artifacts or [
            {"app": ["Example.app"], "target": "/Applications/Example.app"}
        ]}

    def test_clean_cask_exposes_only_its_declared_app_and_links(self):
        document = self.cask("example", artifacts=[
            {"app": ["Example.app"], "target": "/Applications/Example.app"},
            {"binary": ["$APPDIR/Example.app/Contents/MacOS/cli"],
             "target": "$HOMEBREW_PREFIX/bin/example"},
            {"zap": [{"trash": "~/private-data"}]},
        ])
        result = policy.classify_homebrew({"example": "Example.app"}, lambda *_: document)
        self.assertEqual(result, {"skipped": {}, "artifacts": {"example": {
            "/Applications/Example.app": {"kind": "app"},
            "/opt/homebrew/bin/example": {"kind": "link", "source": "/Applications/Example.app/Contents/MacOS/cli"}
        }}})

    def test_transitive_jdk_skips_requested_owner_not_just_the_dependency(self):
        records = {
            ("cask", "example"): self.cask("example", {"cask": ["helper"]}),
            ("cask", "helper"): self.cask("helper", {"formula": ["compiler"]}),
            ("formula", "compiler"): {"dependencies": ["openjdk@21"], "build_dependencies": [], "uses_from_macos": [], "requirements": []},
            ("formula", "openjdk@21"): {"dependencies": [], "build_dependencies": [], "uses_from_macos": [], "requirements": []},
        }
        result = policy.classify_homebrew({"example": "Example.app"}, lambda k, n: records[k, n])
        self.assertEqual(result, {"skipped": {"example": "Forbidden Java/Maven/Android dependency: openjdk@21"}, "artifacts": {}})
        del records["formula", "openjdk@21"]
        with self.assertRaises(KeyError):
            policy.classify_homebrew({"example": "Example.app"}, lambda k, n: records[k, n])

    def test_unknown_footprints_fail_instead_of_becoming_manual_exceptions(self):
        for artifact in [{"pkg": ["Example.pkg"]}, {"postflight": None},
                         {"uninstall": [{"script": "arbitrary-script"}]},
                         {"binary": ["$APPDIR/Example.app/cli"], "target": "$HOMEBREW_PREFIX/../outside"}]:
            with self.subTest(artifact=artifact), self.assertRaises(ValueError):
                policy.classify_homebrew({"example": "Example.app"}, lambda *_: self.cask("example", artifacts=[artifact]))
        records = {
            ("cask", "example"): self.cask("example", {"formula": ["new-library"]}),
            ("formula", "new-library"): {"dependencies": [], "build_dependencies": [], "uses_from_macos": [], "requirements": []},
        }
        with self.assertRaisesRegex(ValueError, "dependency footprint"):
            policy.classify_homebrew({"example": "Example.app"}, lambda k, n: records[k, n])

        with self.assertRaisesRegex(ValueError, "invalid Homebrew dependency list"):
            policy.classify_homebrew({"example": "Example.app"}, lambda *_: self.cask("example", {"formula": ""}))

    def test_source_hash_and_platform_variation_are_bound_to_installation_input(self):
        import hashlib
        import tempfile
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            source = root / "Casks/e/example.rb"
            source.parent.mkdir(parents=True)
            source.write_text('cask "example" do\nend\n')
            doc = self.cask("example") | {
                "ruby_source_path": "Casks/e/example.rb",
                "ruby_source_checksum": {"sha256": hashlib.sha256(source.read_bytes()).hexdigest()},
                "variations": {"arm64_tahoe": {"depends_on": {"formula": ["openjdk"]}}},
            }
            selected = policy.homebrew_record("cask", "example", doc, root, "arm64_tahoe")
            self.assertEqual(selected["depends_on"], {"formula": ["openjdk"]})
            source.write_text("changed upstream source")
            with self.assertRaisesRegex(ValueError, "source mismatch"):
                policy.homebrew_record("cask", "example", doc, root, "arm64_tahoe")


if __name__ == "__main__":
    unittest.main()
