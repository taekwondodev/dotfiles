#!/usr/bin/env python3
"""Owned launcher and release-metadata boundaries, without running Hermes."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class HermesCLI(unittest.TestCase):
    def test_packaged_profile_routing_arguments_and_failure(self):
        with tempfile.TemporaryDirectory(prefix="hermes fixture ") as directory:
            root = Path(directory)
            upstream = root / "upstream" / "bin"
            owned = root / "owned" / "bin"
            upstream.mkdir(parents=True)
            owned.mkdir(parents=True)
            for command in ("hermes", "hermes-agent"):
                fake = upstream / command
                fake.write_text('#!/bin/sh\n[ "$HERMES_DISABLE_LAZY_INSTALLS" = 1 ] || exit 99\nprintf "%s\\0" "$HERMES_HOME" "$PWD" "$@"\nexit 42\n')
                fake.chmod(0o755)
                launcher = (ROOT / "nix/hermes-launcher.sh").read_text()
                (owned / command).write_text(launcher.replace("@hermes@", str(upstream.parent)).replace("@command@", command))
                (owned / command).chmod(0o755)
            env = {**os.environ, "HOME": str(root), "HERMES_HOME": str(root / "custom home"), "HERMES_DISABLE_LAZY_INSTALLS": "0"}
            for profile in ("apple-dev", "wiki-dev"):
                launcher = root / profile
                launcher.write_text((ROOT / "nix/hermes-profile-launcher.sh").read_text().replace("@hermes@", str(owned.parent)).replace("@profile@", profile))
                result = subprocess.run(["sh", str(launcher), "chat", "--query", "a b", ""], cwd=root, env=env, capture_output=True)
                self.assertEqual(result.returncode, 42)
                self.assertEqual(result.stdout.decode().split("\0"), [env["HERMES_HOME"], str(root.resolve()), "-p", profile, "chat", "--query", "a b", "", ""])

    def test_revision_resolution_isolated_and_fails_closed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fakebin = root / "bin"
            fakebin.mkdir()
            git = fakebin / "git"
            revision = "a" * 40
            git.write_text(f'''#!/bin/bash
set -eu
[[ -z ${{GIT_CONFIG_GLOBAL:-}} && $GIT_CONFIG_NOSYSTEM == 1 && $GIT_TERMINAL_PROMPT == 0 ]]
[[ $HOME == *resolution ]]
case "$*" in
  init*) ;;
  *rev-parse*) printf '%s\\n' {revision} ;;
  *describe*) printf 'v0.21.4-7-gabcdef\\n' ;;
  *fetch*) [[ "$*" == *"https://github.com/NousResearch/hermes-agent.git"* ]] ;;
  *) exit 99 ;;
esac
''')
            git.chmod(0o755)
            env = {**os.environ, "PATH": str(fakebin) + os.pathsep + os.environ["PATH"], "GIT_CONFIG_GLOBAL": "/do-not-read"}
            command = ["bash", str(ROOT / "nix/resolve-hermes-version.sh"), revision]
            target = root / "resolution"
            subprocess.run([*command, str(target)], env=env, check=True, capture_output=True)
            self.assertEqual(json.loads((target / "version.json").read_text()), {"revision": revision, "version": "0.21.4", "distance": 7})
            self.assertNotEqual(subprocess.run([*command, str(target)], env=env, capture_output=True).returncode, 0)
            self.assertNotEqual(subprocess.run([*command[:-1], "invalid", str(root / "invalid")], env=env, capture_output=True).returncode, 0)
            successful_git = git.read_text()
            git.write_text(successful_git.replace("v0.21.4-7-gabcdef", "v0.21.4+canary-7-gabcdef"))
            self.assertNotEqual(subprocess.run([*command, str(root / "canary-resolution")], env=env, capture_output=True).returncode, 0)
            git.write_text(successful_git.replace(revision, "b" * 40))
            self.assertNotEqual(subprocess.run([*command, str(root / "mismatch-resolution")], env=env, capture_output=True).returncode, 0)
            git.write_text("#!/bin/sh\nexit 37\n")
            self.assertNotEqual(subprocess.run([*command, str(root / "failed-resolution")], env=env, capture_output=True).returncode, 0)

    def test_describe_selects_latest_stable_tag_from_a_real_repository(self):
        # Real git runs the production describe flags; only the network fetch
        # is redirected to a local repository with competing tag shapes.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            upstream = root / "upstream"

            def git(*args):
                return subprocess.run(["git", "-C", str(upstream), "-c", "user.name=t", "-c", "user.email=t@t", *args],
                                      check=True, capture_output=True, text=True).stdout.strip()
            upstream.mkdir()
            git("init", "-q")
            for tag in ("v0.21.4", "v0.21.5-rc1", "v2026.4.1", None):
                git("commit", "-q", "--allow-empty", "-m", str(tag))
                if tag:
                    git("tag", tag)
            revision = git("rev-parse", "HEAD")
            real = shutil.which("git")
            fakebin = root / "bin"
            fakebin.mkdir()
            (fakebin / "git").write_text(
                "#!/bin/bash\nargs=()\nfor arg in \"$@\"; do\n  case $arg in\n"
                "    --filter=*) ;;\n"
                f"    https://github.com/NousResearch/hermes-agent.git) args+=(\"{upstream}\") ;;\n"
                "    *) args+=(\"$arg\") ;;\n  esac\ndone\n"
                f"exec \"{real}\" \"${{args[@]}}\"\n")
            (fakebin / "git").chmod(0o755)
            env = {**os.environ, "PATH": str(fakebin) + os.pathsep + os.environ["PATH"]}
            target = root / "resolution"
            subprocess.run(["bash", str(ROOT / "nix/resolve-hermes-version.sh"), revision, str(target)], env=env, check=True, capture_output=True)
            self.assertEqual(json.loads((target / "version.json").read_text()), {"revision": revision, "version": "0.21.4", "distance": 3})


if __name__ == "__main__":
    unittest.main()
