{ pkgs, source }:
assert pkgs.lib.assertMsg (pkgs.lib.versionAtLeast pkgs.swift.version "6.2")
  "Monitor Volume requires Swift 6.2 or newer";
pkgs.stdenv.mkDerivation {
  pname = "monitor-volume";
  version = source.shortRev or "channel";
  src = source;
  strictDeps = true;
  nativeBuildInputs = with pkgs; [
    swift swiftpm imagemagick libicns darwin.autoSignDarwinBinariesHook
  ];
  buildInputs = [ pkgs.apple-sdk_26 (pkgs.darwinMinVersionHook "15.0") ];
  dontConfigure = true;
  # The sole package dependency is in-tree. Keep the publisher manifests intact.
  swiftpmFlags = [ "--product" "MonitorVolume" "-Xswiftc" "-strict-concurrency=complete" ];
  installPhase = ''
    runHook preInstall
    bash ${./monitor-volume-bundle.sh} "$(swiftpmBinPath)" "$PWD" \
      "$out/Applications/Monitor Volume.app"
    runHook postInstall
  '';
  # Sign only the output, after Swift rpath fixups; never query personal keys or
  # invoke upstream's installer, which also stops, replaces and launches apps.
  postFixup = ''
    app="$out/Applications/Monitor Volume.app"
    /usr/bin/codesign --force --deep --sign - --timestamp=none "$app"
    /usr/bin/codesign --verify --deep --strict "$app"
  '';
  meta = {
    description = "Route macOS volume keys to the default external monitor audio output";
    homepage = "https://github.com/taekwondodev/MonitorVolume";
    license = pkgs.lib.licenses.mit;
    platforms = [ "aarch64-darwin" ];
  };
}
