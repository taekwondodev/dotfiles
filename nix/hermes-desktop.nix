{ pkgs, source, cli, electron }:
let
  runtime = cli.runtime;
  # Bind native module compilation and the app to one Electron/headers pair.
  desktop = runtime.hermesDesktop.override { inherit electron; };
in
pkgs.runCommand "hermes-desktop-macos-${source.shortRev or "channel"}" {
  nativeBuildInputs = [ pkgs.python3 pkgs.nodejs_latest ];
  meta = {
    description = "Hermes desktop app using the Nix-owned Hermes runtime";
    mainProgram = "hermes-desktop";
    platforms = [ "aarch64-darwin" ];
    inherit (desktop.meta) license homepage;
  };
} ''
  # Metadata only: consume the publisher's current identity/privacy declarations.
  # Do not invoke electron-builder, signing callbacks, installers or login flows.
  node - ${source}/apps/desktop/electron-builder.config.cjs > identity.json <<'JS'
  const config = require(process.argv[2]);
  process.stdout.write(JSON.stringify({
    productName: config.productName,
    appId: config.appId,
    executableName: config.executableName,
    protocols: config.protocols,
    mac: { category: config.mac.category, extendInfo: config.mac.extendInfo }
  }));
  JS
  mkdir -p "$out/Applications" "$out/bin"
  app="$out/Applications/Hermes.app"
  python3 ${./hermes-desktop-bundle.py} \
    ${electron}/Applications/Electron.app \
    ${desktop}/share/hermes-desktop ${source} identity.json \
    ${cli}/bin/hermes ${runtime.version} "$app"

  # Rebrand only the main/helper bundles. The Electron framework is unchanged.
  # Ad-hoc signing never selects a personal key, contacts a timestamp server or
  # requests notarization. This runs ONLY during an explicitly requested build.
  for helper in "$app"/Contents/Frameworks/Hermes\ Helper*.app; do
    /usr/bin/codesign --force --sign - --timestamp=none --options runtime \
      --entitlements ${source}/apps/desktop/electron/entitlements.mac.inherit.plist "$helper"
  done
  /usr/bin/codesign --force --sign - --timestamp=none --options runtime \
    --entitlements ${source}/apps/desktop/electron/entitlements.mac.plist "$app"
  /usr/bin/codesign --verify --deep --strict "$app"

  # Same native app for terminal and Finder; relaunch re-enters the ESM policy.
  cat > "$out/bin/hermes-desktop" <<EOF
  #!${pkgs.runtimeShell}
  exec "$app/Contents/MacOS/Hermes" "\$@"
  EOF
  chmod +x "$out/bin/hermes-desktop"
''
