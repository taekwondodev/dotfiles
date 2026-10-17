{ pkgs, source, version }:
let
  src = builtins.path {
    path = builtins.toPath source;
    name = "pi-release-metadata";
    filter = path: type: type == "directory" || builtins.elem (builtins.baseNameOf path) [ "package.json" "package-lock.json" "source-integrity.json" ];
  };
  manifest = builtins.fromJSON (builtins.readFile (src + "/package.json"));
  lock = builtins.fromJSON (builtins.readFile (src + "/package-lock.json"));
  integrity = builtins.fromJSON (builtins.readFile (src + "/source-integrity.json"));
  piName = "@earendil-works/pi-coding-agent";
  matches = manifest.version == version && manifest.dependencies.${piName} == version
    && lock.lockfileVersion == 3 && lock.version == version
    && lock.packages."".version == version && lock.packages."".dependencies.${piName} == version
    && lock.packages."node_modules/${piName}".version == version;
in
assert pkgs.lib.assertMsg matches "Pi publisher manifest/lock does not match dev's required release";
pkgs.buildNpmPackage {
  pname = "pi-runtime";
  inherit version src;
  nodejs = pkgs.nodejs_latest;
  npmDeps = pkgs.importNpmLock {
    npmRoot = src;
    packageSourceOverrides = pkgs.lib.mapAttrs (module: hash:
      assert (lock.packages.${module}.integrity or null) == null;
      pkgs.fetchurl {
        url = lock.packages.${module}.resolved;
        inherit hash;
      }) integrity;
  };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/pi" "$out/bin"
    cp -R node_modules "$out/lib/pi/"
    # Retain the publisher's metadata, not npmConfigHook's build-local mapping.
    cp ${src}/package{,-lock}.json "$out/lib/pi/"
    piRoot="$out/lib/pi/node_modules/@earendil-works/pi-coding-agent"
    test -f "$piRoot/dist/index.js"
    test -f "$piRoot/dist/cli.js"
    # Refuse self-update before it requests versions or touches another install.
    substituteInPlace "$piRoot/dist/package-manager-cli.js" \
      --replace-fail 'async function getSelfUpdatePlan(force) {' \
        'async function getSelfUpdatePlan(force) {
          throw new Error("Pi is managed by Nix; rerun scripts/bootstrap.sh from the dotfiles checkout.");'
    substitute ${./pi-launcher.sh} "$out/bin/pi" \
      --subst-var-by pi "$out" --subst-var-by node ${pkgs.nodejs_latest}
    chmod +x "$out/bin/pi"
    runHook postInstall
  '';
  meta.platforms = [ "aarch64-darwin" ];
}
