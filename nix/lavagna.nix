{ pkgs, source }:
# The public module requires Go >=1.27.1; nixpkgs' default Go is older.
(pkgs.buildGoModule.override { go = pkgs.go_latest; }) {
  pname = "lavagna";
  version = source.shortRev or "channel";
  src = source;
  vendorHash = null; # Standard library only; keep upstream go.mod intact.
  subPackages = [ "." ];
  env.CGO_ENABLED = 0;
  nativeBuildInputs = with pkgs; [ swift imagemagick libicns darwin.autoSignDarwinBinariesHook ];
  buildInputs = [ pkgs.apple-sdk_26 (pkgs.darwinMinVersionHook "13.0") ];
  postBuild = ''
    swiftc -O -target arm64-apple-macosx13.0 \
      -o "$TMPDIR/lavagna-notifier" macos/notifier/main.swift
  '';
  postInstall = ''
    bash ${./lavagna-bundle.sh} "$TMPDIR/lavagna-notifier" "$PWD" "$out/Applications/Lavagna.app"
    install -Dm644 LICENSE "$out/share/licenses/lavagna/LICENSE"
    install -Dm644 internal/page/assets/fonts/OFL.txt "$out/share/licenses/lavagna/fonts/OFL.txt"
    install -Dm644 internal/page/assets/fonts/SOURCE.txt "$out/share/licenses/lavagna/fonts/SOURCE.txt"
  '';
  # Only sign build outputs after native fixups. Upstream's installer also
  # replaces user apps, registers LaunchServices and opens a permission prompt.
  postFixup = ''
    app="$out/Applications/Lavagna.app"
    /usr/bin/codesign --force --deep --sign - --timestamp=none "$app"
    /usr/bin/codesign --verify --deep --strict "$app"
  '';
  meta = {
    description = "Browser-based agent conversation rounds with native macOS notifications";
    homepage = "https://github.com/taekwondodev/lavagna";
    license = with pkgs.lib.licenses; [ mit ofl ];
    mainProgram = "lavagna";
    platforms = [ "aarch64-darwin" ];
  };
}
