#!/usr/bin/env python3
"""Evaluate personal configuration with inert skills; never launch Claude."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ClaudeConfig(unittest.TestCase):
    def test_portable_seed_and_individual_skills_leave_runtime_state_unmanaged(self):
        with tempfile.TemporaryDirectory(prefix="claude config ") as temporary:
            source = Path(temporary)
            for name in ("first", "second", "synced", "not-a-skill"):
                directory = source / "skills" / name
                directory.mkdir(parents=True)
                if name != "not-a-skill":
                    (directory / "SKILL.md").write_text("# Inert fixture\n")
            expression = '''
              let
                make = packages: import (builtins.toPath (builtins.getEnv "DOTFILES_TEST_ROOT" + "/nix/agent-config.nix")) {
                  inputs.skills = builtins.getEnv "DOTFILES_TEST_SKILLS";
                  inventory = { inherit packages; };
                };
                configured = make { claude-code = "/fixture/claude"; };
                skipped = make {};
                claudePaths = attrs: builtins.removeAttrs attrs (builtins.filter
                  (name: builtins.substring 0 8 name != ".claude/") (builtins.attrNames attrs));
              in {
                shared = configured.files.".agents/skills";
                files = claudePaths configured.files;
                seeds = builtins.attrNames (claudePaths configured.seeds);
                settings = builtins.fromJSON (builtins.readFile configured.seeds.".claude/settings.json");
                skippedFiles = claudePaths skipped.files;
                skippedSeeds = claudePaths skipped.seeds;
                skippedShared = skipped.files.".agents/skills";
              }
            '''
            result = subprocess.run([
                os.environ.get("NIX_BIN", "nix"), "--extra-experimental-features", "nix-command",
                "--option", "allow-import-from-derivation", "false", "eval", "--impure",
                "--json", "--expr", expression,
            ], env={**os.environ, "DOTFILES_TEST_ROOT": str(ROOT), "DOTFILES_TEST_SKILLS": str(source)},
                capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            evaluated = json.loads(result.stdout)
            self.assertEqual(evaluated["shared"], str(source / "skills"))
            self.assertEqual(evaluated["files"], {
                ".claude/skills/first": str(source / "skills/first"),
                ".claude/skills/second": str(source / "skills/second"),
            })
            self.assertEqual(evaluated["seeds"], [".claude/settings.json"])
            self.assertEqual(evaluated["settings"], {
                "model": "fable", "autoMemoryEnabled": False,
                "attribution": {"commit": "", "pr": ""},
                "modelSettings": {
                    "claude-opus-5-5": {"effortLevel": "high"},
                    "claude-fable-5-1": {"effortLevel": "high"},
                },
            })
            self.assertEqual(evaluated["skippedFiles"], {})
            self.assertEqual(evaluated["skippedSeeds"], {})
            self.assertEqual(evaluated["skippedShared"], str(source / "skills"))


if __name__ == "__main__":
    unittest.main()
