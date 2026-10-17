{ pkgs, source, cli }:
let
  runtime = cli.runtime;
in
assert pkgs.lib.assertMsg (pkgs.lib.versionAtLeast pkgs.swift.version "6.2")
  "HermesUsageMonitor requires Swift 6.2 or newer";
pkgs.stdenv.mkDerivation {
  pname = "hermes-usage-monitor";
  version = source.shortRev or "channel";
  src = source;
  strictDeps = true;
  nativeBuildInputs = with pkgs; [ swift swiftpm actool python3 darwin.autoSignDarwinBinariesHook ];
  buildInputs = [ pkgs.apple-sdk_26 (pkgs.darwinMinVersionHook "26.0") ];
  dontConfigure = true;
  # No external Swift dependencies. Preserve the publisher manifest/locks.
  swiftpmFlags = [ "--product" "HermesUsageMonitor" ];

  installPhase = ''
    runHook preInstall
    python3 ${./hermes-usage-monitor-bundle.py} "$(swiftpmBinPath)" "$PWD" \
      ${runtime.hermesVenv}/bin/python3 \
      ${runtime.hermesVenv}/${runtime.python.sitePackages}/agent/account_usage.py \
      "$out/Applications/HermesUsageMonitor.app"
    # Keep the upstream catalog, including its template menu-bar identity.
    # Nixpkgs' actool avoids a dependency on an impure host Xcode installation.
    actool --compile "$out/Applications/HermesUsageMonitor.app/Contents/Resources" \
      --platform macosx --minimum-deployment-target 26.0 --app-icon AppIcon \
      --output-partial-info-plist "$TMPDIR/assetcatalog-info.plist" \
      Sources/HermesUsageMonitorApp/Resources/Media.xcassets
    runHook postInstall
  '';
  # Sign after Swift's rpath fixups. Never run upstream's installer, which also
  # replaces a user app, terminates a running instance and launches the result.
  postFixup = ''
    app="$out/Applications/HermesUsageMonitor.app"
    /usr/bin/codesign --force --deep --sign - --timestamp=none "$app"
    /usr/bin/codesign --verify --deep --strict "$app"
  '';
  meta = {
    description = "Native Hermes subscription quota and usage menu-bar app";
    homepage = "https://github.com/taekwondodev/HermesUsageMonitor";
    license = pkgs.lib.licenses.unfree;
    platforms = [ "aarch64-darwin" ];
  };
}
