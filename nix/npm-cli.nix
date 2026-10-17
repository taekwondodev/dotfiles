{ pkgs, source }:
# This is a fresh installation-project lock resolved by the Nix runner from the
# publishers' npm channels, NOT a rewrite of either upstream project lockfile.
let
  src = builtins.path {
    path = builtins.toPath source;
    name = "dotfiles-npm-resolution";
    filter = path: type: type == "directory" || builtins.elem (builtins.baseNameOf path) [ "package.json" "package-lock.json" ];
  };
  lock = builtins.fromJSON (builtins.readFile (src + "/package-lock.json"));
in
assert pkgs.lib.assertMsg (lock.packages ? "node_modules/pi-claude-bridge") "Missing Pi bridge metadata";
pkgs.buildNpmPackage {
  pname = "gh-axi";
  version = lock.packages."node_modules/gh-axi".version;
  inherit src;
  nodejs = pkgs.nodejs_latest;
  npmDeps = pkgs.importNpmLock { npmRoot = src; };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  # Pi supplies its extension peers; do not install another Pi via the bridge.
  npmFlags = [ "--ignore-scripts" "--legacy-peer-deps" ];
  dontNpmBuild = true;
  nativeBuildInputs = [ pkgs.makeWrapper ];
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin"
    cp -R node_modules "$out/lib/"
    test -f "$out/lib/node_modules/pi-claude-bridge/src/index.ts"
    makeWrapper ${pkgs.nodejs_latest}/bin/node "$out/bin/gh-axi" \
      --add-flags "$out/lib/node_modules/gh-axi/dist/bin/gh-axi.js" \
      --set-default GH_BIN ${pkgs.gh}/bin/gh
    runHook postInstall
  '';
}
