#!/usr/bin/env python3
"""Parse evaluated dormant plists; never execute a service or launchctl."""
import json
import os
from pathlib import Path
import plistlib
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
DIRECTORY = ".local/share/dotfiles/services/"
GATEWAY = DIRECTORY + "ai.hermes.gateway.plist"
ENVIRONMENT = DIRECTORY + "com.hermes.claude-subscription-directsdk-env.plist"


class ManualServices(unittest.TestCase):
    def test_dormant_definitions_preserve_literal_paths_and_owned_commands(self):
        home = '/Users/Fresh & <Home> \'";$(touch must-not-exist)'
        expression = '''
          let
            root = builtins.getEnv "DOTFILES_TEST_ROOT";
            args = {
              lib = (builtins.getFlake root).inputs.nixpkgs.lib;
              homeDirectory = builtins.getEnv "DOTFILES_TEST_HOME";
              profileDirectory = "/fixture/managed profile";
              hermes = { outPath = "/fixture/hermes cli"; runtime.hermesVenv = "/fixture/hermes python"; };
              claude = "/fixture/claude code";
            };
            make = overrides: import (builtins.toPath (root + "/nix/manual-services.nix")) (args // overrides);
          in {
            files = make {};
            noHermes = make { hermes = null; };
            noClaude = make { claude = null; };
            noPackages = make { hermes = null; claude = null; };
          }
        '''
        result = subprocess.run([
            os.environ.get("NIX_BIN", "nix"), "--extra-experimental-features", "nix-command flakes",
            "--option", "allow-import-from-derivation", "false", "eval", "--impure",
            "--reference-lock-file", str(ROOT / "flake.lock"), "--no-update-lock-file",
            "--json", "--expr", expression,
        ], cwd=ROOT, env={**os.environ, "DOTFILES_TEST_ROOT": str(ROOT), "DOTFILES_TEST_HOME": home},
            capture_output=True, text=True, check=True)
        evaluated = json.loads(result.stdout)
        self.assertEqual(set(evaluated["files"]), {GATEWAY, ENVIRONMENT})
        jobs = {key: plistlib.loads(value["text"].encode()) for key, value in evaluated["files"].items()}
        gateway = jobs[GATEWAY]
        self.assertEqual(gateway["Label"], "ai.hermes.gateway")
        self.assertEqual(gateway["ProgramArguments"], [
            "/fixture/hermes python/bin/python3", "-m", "hermes_cli.stderr_timestamp",
            "--error-log", home + "/.hermes/logs/gateway.error.log", "--",
            "/fixture/hermes cli/bin/hermes", "gateway", "run", "--external-supervisor",
        ])
        self.assertEqual(gateway["WorkingDirectory"], home + "/.hermes")
        self.assertEqual(gateway["StandardOutPath"], home + "/.hermes/logs/gateway.log")
        self.assertEqual(gateway["StandardErrorPath"], home + "/.hermes/logs/gateway.error.log")
        self.assertEqual(gateway["EnvironmentVariables"], {
            "HOME": home, "HERMES_HOME": home + "/.hermes", "HERMES_SUPERVISED_CHILD": "1",
            "HERMES_DISABLE_LAZY_INSTALLS": "1", "PYTHONDONTWRITEBYTECODE": "1",
            "PATH": "/fixture/managed profile/bin:/usr/bin:/bin:/usr/sbin:/sbin",
            "CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND": "/fixture/claude code/bin/claude",
        })
        self.assertTrue(gateway["RunAtLoad"])
        self.assertEqual(gateway["KeepAlive"], {"SuccessfulExit": False})
        self.assertEqual((gateway["ThrottleInterval"], gateway["ExitTimeOut"]), (30, 60))
        self.assertEqual(gateway["SoftResourceLimits"], {"NumberOfFiles": 4096})
        self.assertEqual(gateway["LimitLoadToSessionType"], ["Aqua", "Background"])
        self.assertEqual(jobs[ENVIRONMENT], {
            "Label": "com.hermes.claude-subscription-directsdk-env", "RunAtLoad": True,
            "ProgramArguments": ["/bin/launchctl", "setenv", "CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND", "/fixture/claude code/bin/claude"],
        })
        self.assertEqual(set(evaluated["noHermes"]), {ENVIRONMENT})
        self.assertEqual(set(evaluated["noClaude"]), {GATEWAY})
        without_claude = plistlib.loads(evaluated["noClaude"][GATEWAY]["text"].encode())
        self.assertNotIn("CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND", without_claude["EnvironmentVariables"])
        self.assertEqual(evaluated["noPackages"], {})


if __name__ == "__main__":
    unittest.main()
