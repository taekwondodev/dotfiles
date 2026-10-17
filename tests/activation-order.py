#!/usr/bin/env python3
"""The generation is recorded only after activation-time admission; never activates."""
import os
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
RECORD = '/bin/nix-env --profile /nix/var/nix/profiles/system --set "$systemConfig"'


def evaluate(attribute):
    return subprocess.run([
        os.environ.get("NIX_BIN", "nix"), "--extra-experimental-features", "nix-command flakes",
        "--option", "allow-import-from-derivation", "false", "eval", "--impure",
        "--reference-lock-file", str(ROOT / "flake.lock"), "--no-update-lock-file",
        "--raw", f"{ROOT}#{attribute}",
    ], check=True, capture_output=True, text=True).stdout


class ActivationOrder(unittest.TestCase):
    def test_record_follows_every_admission_and_precedes_mutation(self):
        script = evaluate("darwinConfigurations.fresh-mac.config.system.activationScripts.script.text")
        record = script.index(RECORD)
        self.assertEqual(script.count(RECORD), 1)
        # nix-darwin's checks can still refuse, and end check mode, after preActivation.
        checks_end = script.index('if [[ "${checkActivation:-0}" -eq 1 ]]; then')
        for refusal in ("dotfiles_admit ", "dotfiles_admit_account ", "dotfiles_admit_native ", "dotfiles_admit_casks ",
                        "Homebrew metadata resolved for a different macOS version", "Refusing incomplete configuration"):
            self.assertLess(script.index(refusal), checks_end, refusal)
        self.assertLess(checks_end, record)
        for mutation in ("dscl . -create", "setting up /etc", "setting up Homebrew prefixes", "brew bundle",
                         'ln -sfn "$(readlink -f "$systemConfig")" /run/current-system'):
            self.assertIn(mutation, script)
            self.assertLess(record, script.index(mutation), mutation)

    def test_runner_does_not_record_before_activation(self):
        runner = evaluate("packages.aarch64-darwin.bootstrap.text")
        self.assertNotIn("nix-env", runner)
        self.assertIn('darwin-rebuild" activate', runner)


if __name__ == "__main__":
    unittest.main()
