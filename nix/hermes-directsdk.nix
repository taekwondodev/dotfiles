{ pkgs, source }:
let
  plugin = source + "/claude-subscription-directsdk";
  project = builtins.fromTOML (builtins.readFile (plugin + "/pyproject.toml"));
in
assert pkgs.lib.assertMsg (project.project.dependencies == [])
  "DirectSDK acquired Python dependencies; package them before updating its external runtime";
pkgs.runCommand "hermes-directsdk-${source.shortRev or "channel"}" {} ''
  cp -R ${plugin} "$out"
  chmod u+w "$out/plugin.yaml"
  # Supported PM ownership marker: do not enroll this Nix-owned plugin as a
  # mutable workspace member just because it carries pyproject.toml metadata.
  if grep -q '^python_runtime:' "$out/plugin.yaml"; then
    echo 'Recheck the upstream DirectSDK runtime ownership declaration' >&2
    exit 1
  fi
  printf '\npython_runtime: external\n' >> "$out/plugin.yaml"
''
