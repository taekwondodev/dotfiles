{ pkgs, inputs, system, npmSource ? "", portKillLock ? "", piSource ? "", hermesVersion ? "" }:
let
  npmTools = import ./npm-cli.nix { inherit pkgs; source = npmSource; };
  hermesCLI = import ./hermes-cli.nix { inherit pkgs inputs system; versionFile = hermesVersion; };
  devManifest = builtins.fromJSON (builtins.readFile (inputs.dev-source + "/package.json"));
  pi = import ./pi-runtime.nix { inherit pkgs; source = piSource; version = devManifest.config.pi; };
  upstreamLock = inputs.port-kill-source + "/Cargo.lock";
  portKillLockFile = if builtins.pathExists upstreamLock then upstreamLock
    else if portKillLock != "" then builtins.path { path = portKillLock; name = "port-kill-Cargo.lock"; }
    else null;
  ideviceRelease = builtins.fromJSON (builtins.readFile inputs.idevice-pair-release.outPath);
  ideviceAsset = pkgs.lib.findFirst (asset: asset.name == "idevice_pair--macos-universal.dmg")
    (throw "The latest idevice_pair release has no macOS universal artifact") ideviceRelease.assets;
in {
  # Keys are the reportable components. Each automatic component has one owner.
  packages = {
    inherit (pkgs) git gh git-filter-repo fd ripgrep fzf tmux autojump shellcheck
      tree-sitter fish starship vim python3 uv rustc cargo cmake ninja clang
      gopls clang-tools typescript-language-server bash-language-server
      lua-language-server pyright rust-analyzer dockerfile-language-server
      terraform-ls docker-compose-language-service yaml-language-server
      sourcekit-lsp stylua shfmt prettier black swift-format gofumpt
      ffmpeg yt-dlp tesseract poppler iloader claude-code github-copilot-cli;
    node-npm = pkgs.nodejs_latest;
    go = pkgs.go_latest;
    neovim = pkgs.neovim.override { withPython3 = false; withRuby = false; };
    # The basic scheme supplies pdfLaTeX, BibTeX and makeindex.
    tex = pkgs.texliveBasic.withPackages (ps: with ps; [
      xetex latexmk biblatex biber
      collection-latexrecommended collection-fontsrecommended
      babel-english babel-italian hyphen-italian
      # Use Nix for packages and the existing PDF viewer, not TeX GUI tools.
      { pname = "tlshell"; }
      { pname = "xdvi"; }
    ]);
    spotify-spotx = inputs.spotx.packages.${system}.default;
    jetbrains-mono = pkgs.nerd-fonts.jetbrains-mono;
    proto-nerd-font = pkgs.nerd-fonts._0xproto;
    termicons = pkgs.runCommand "termicons-font" {} ''
      install -Dm644 ${inputs.termicons-font.outPath} "$out/share/fonts/truetype/termicons.ttf"
    '';
    aptos = pkgs.stdenvNoCC.mkDerivation {
      pname = "aptos-fonts";
      version = "channel";
      src = inputs.aptos-fonts.outPath;
      nativeBuildInputs = [ pkgs.unzip ];
      unpackPhase = ''unzip "$src"'';
      installPhase = ''
        mkdir -p "$out/share/fonts/truetype"
        find . -name '*.ttf' -exec install -m644 -t "$out/share/fonts/truetype" {} +
      '';
      meta.license = pkgs.lib.licenses.unfree;
    };
    idevice-pair = pkgs.stdenvNoCC.mkDerivation {
      pname = "idevice-pair";
      version = pkgs.lib.removePrefix "v" ideviceRelease.tag_name;
      src = pkgs.fetchurl {
        url = ideviceAsset.browser_download_url;
        sha256 = pkgs.lib.removePrefix "sha256:" ideviceAsset.digest;
      };
      nativeBuildInputs = [ pkgs.undmg ];
      unpackPhase = ''undmg "$src"'';
      installPhase = ''
        mkdir -p "$out/Applications"
        cp -R idevice_pair.app "$out/Applications/"
      '';
    };
    monitor-volume = import ./monitor-volume.nix { inherit pkgs; source = inputs.monitor-volume; };
    fira-code = pkgs.fira-code;
    montserrat = pkgs.montserrat;
    open-sans = pkgs.open-sans;
    lavagna = import ./lavagna.nix { inherit pkgs; source = inputs.lavagna; };
  } // pkgs.lib.optionalAttrs (portKillLockFile != null) {
    port-kill = import ./port-kill.nix {
      inherit pkgs;
      source = inputs.port-kill-source;
      lockFile = portKillLockFile;
    };
  } // pkgs.lib.optionalAttrs (piSource != "") {
    inherit pi;
    dev = import ./dev-package.nix { inherit pkgs pi; source = inputs.dev-source; };
  } // pkgs.lib.optionalAttrs (hermesVersion != "") {
    hermes-cli = hermesCLI;
    hermes-usage-monitor = import ./hermes-usage-monitor.nix {
      inherit pkgs;
      source = inputs.hermes-usage-monitor;
      cli = hermesCLI;
    };
    hermes-desktop = import ./hermes-desktop.nix {
      inherit pkgs;
      source = inputs.hermes-agent;
      cli = hermesCLI;
      # Must match the Electron runtime/headers used for upstream node-pty.
      electron = inputs.hermes-agent.inputs.nixpkgs.legacyPackages.${system}.electron;
    };
  } // pkgs.lib.optionalAttrs (npmSource != "") {
    gh-axi = npmTools;
    pi-claude-bridge = npmTools;
  };
  piRelease = devManifest.config.pi;
  hermesRevision = inputs.hermes-agent.rev;
  npmRequests = {
    name = "dotfiles-cli-resolution";
    version = "0.0.0";
    private = true;
    dependencies = { gh-axi = "latest"; pi-claude-bridge = "latest"; };
  };
  # App paths are explicit so admission does not infer ownership from presence.
  casks = {
    ghostty = "Ghostty.app";
    "1password" = "1Password.app";
    google-chrome = "Google Chrome.app";
    raycast = "Raycast.app";
    obsidian = "Obsidian.app";
    whatsapp = "WhatsApp.app";
    discord = "Discord.app";
    linear = "Linear.app";
    stats = "Stats.app";
    ankerwork = "AnkerWork.app";
  };
  manual = {
    "Fish login shell" = "Run `chsh -s /run/current-system/sw/bin/fish` once; nix-darwin registers Fish in /etc/shells but changes an account's shell only for users it fully manages, by owner choice.";
    "Logi Options+" = "Install manually from Logitech; its vendor installer is not run by bootstrap, by owner choice.";
    "Microsoft Teams" = "Install manually from Microsoft; its pkg installer is not run by bootstrap, by owner choice.";
    "SF Symbols" = "Install manually from Apple; its pkg installer is not run by bootstrap, by owner choice.";
    OrbStack = "Install manually from OrbStack; its installer and postflight setup are not run by bootstrap, by owner choice.";
    "VMware Fusion" = "Homebrew removed this cask because downloads require Broadcom authentication; install through the owner's authorized vendor account. No virtual machines or data are restored.";
    Xcode = "Apple-authorized download, license acceptance and SDK/simulator selection are manual; no accounts or provisioning state are restored.";
    Wipr = "Paid Mac App Store installation requires the owner's Apple account.";
    "1Password for Safari" = "Install/enable the Safari extension through the owner's authorized App Store/Safari flow.";
    Consolas = "Use the owner's licensed Microsoft distribution; no font binaries are copied from this Mac.";
    "Raycast personalization" = "Configure preferences, shortcuts and Store extensions in Raycast. Its documented v2 transfer flow is interactive and uses an encrypted full-data export; no reviewed settings-only source is supplied. No private state is imported. See README.";
  };
  # Pending investigation is NOT an allowed manual skip. The runner refuses to
  # activate while any of these obligations remains unresolved.
  pending = pkgs.lib.optional (npmSource == "") "gh-axi/Pi bridge npm metadata resolution"
    ++ pkgs.lib.optional (portKillLockFile == null) "port-kill/port-kill-console Cargo metadata resolution"
    ++ pkgs.lib.optional (piSource == "") "dev/Pi publisher release metadata"
    ++ pkgs.lib.optional (hermesVersion == "") "Hermes source release metadata";
}
