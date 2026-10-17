{ pkgs, inputs, system, versionFile }:
let
  provenance = builtins.fromJSON (builtins.readFile versionFile);
  # Use the upstream complete runtime: personal settings select optional web,
  # voice and provider capabilities. No uv/pip dependency repair at launch.
  upstream = inputs.hermes-agent.packages.${system}.default.override {
    inherit (provenance) version distance;
  };
in
assert pkgs.lib.assertMsg (provenance.revision == inputs.hermes-agent.rev
  && builtins.match "[0-9]+\\.[0-9]+\\.[0-9]+" provenance.version != null
  && builtins.isInt provenance.distance && provenance.distance >= 0)
  "Hermes version metadata does not match the selected source revision";
pkgs.runCommand "hermes-cli-${inputs.hermes-agent.shortRev or "channel"}" {
  meta = {
    description = "Hermes CLI and personal profile launchers";
    mainProgram = "hermes";
    platforms = [ "aarch64-darwin" ];
  };
  passthru = {
    runtime = upstream;
    providerPlugin = import ./hermes-directsdk.nix { inherit pkgs; source = inputs.hermes-plugins; };
  };
} ''
  mkdir -p "$out/bin"
  # Deliberate public command surface: no hermes-acp adapter or desktop app.
  # Keep upstream's sealed runtime/locks intact behind these entrypoints.
  for command in hermes hermes-agent; do
    test -x ${upstream}/bin/"$command"
    substitute ${./hermes-launcher.sh} "$out/bin/$command" \
      --subst-var-by hermes ${upstream} --subst-var-by command "$command"
    chmod +x "$out/bin/$command"
  done
  for profile in apple-dev wiki-dev; do
    substitute ${./hermes-profile-launcher.sh} "$out/bin/$profile" \
      --subst-var-by hermes "$out" --subst-var-by profile "$profile"
    chmod +x "$out/bin/$profile"
  done
''
