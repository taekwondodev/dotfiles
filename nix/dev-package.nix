{ pkgs, source, pi }:
let manifest = builtins.fromJSON (builtins.readFile (source + "/package.json"));
in pkgs.buildNpmPackage {
  pname = "dev-pi-environment";
  version = source.shortRev or manifest.version;
  src = source;
  patches = [ ./dev-coordination.patch ];
  nodejs = pkgs.nodejs_latest;
  npmDeps = pkgs.importNpmLock { npmRoot = source; };
  npmConfigHook = pkgs.importNpmLock.npmConfigHook;
  npmFlags = [ "--ignore-scripts" "--omit=dev" ];
  dontNpmBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/dev" "$out/bin"
    # Node runs upstream TypeScript directly. No private profiles, local state,
    # maintenance installers or existing node_modules are copied from this Mac.
    cp -R src config node_modules "$out/lib/dev/"
    cp ${source}/LICENSE ${source}/package{,-lock}.json "$out/lib/dev/"
    ln -s ${pi}/lib/pi/node_modules/@earendil-works "$out/lib/dev/node_modules/@earendil-works"
    substitute ${./dev-launcher.sh} "$out/bin/dev" \
      --subst-var-by dev "$out" --subst-var-by pi ${pi} --subst-var-by node ${pkgs.nodejs_latest}
    chmod +x "$out/bin/dev"
    runHook postInstall
  '';
  meta.platforms = [ "aarch64-darwin" ];
}
