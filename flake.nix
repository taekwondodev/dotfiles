{
  description = "Personal fresh Apple Silicon Mac setup";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:nix-darwin/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = { url = "github:Homebrew/homebrew-core"; flake = false; };
    homebrew-cask = { url = "github:Homebrew/homebrew-cask"; flake = false; };
    # Keep SpotX's OWN validated inputs. Do not overlay it onto our newer pkgs.
    spotx.url = "github:SpotX-Official/SpotX-Nix";
    lavagna = { url = "github:taekwondodev/lavagna"; flake = false; };
    skills = { url = "github:taekwondodev/skills"; flake = false; };
    dev-source = { url = "github:taekwondodev/dev"; flake = false; };
    # Retain Hermes upstream's tested Python/Node inputs and dependency locks.
    hermes-agent.url = "github:NousResearch/hermes-agent";
    hermes-usage-monitor = { url = "github:taekwondodev/HermesUsageMonitor"; flake = false; };
    monitor-volume = { url = "github:taekwondodev/MonitorVolume"; flake = false; };
    hermes-plugins = { url = "github:NousResearch/hermes-official-plugins"; flake = false; };
    swiftui-skill = { url = "github:twostraws/SwiftUI-Agent-Skill"; flake = false; };
    swift-concurrency-skill = { url = "github:twostraws/Swift-Concurrency-Agent-Skill"; flake = false; };
    swift-testing-skill = { url = "github:twostraws/Swift-Testing-Agent-Skill"; flake = false; };
    swiftdata-skill = { url = "github:twostraws/SwiftData-Agent-Skill"; flake = false; };
    port-kill-source = { url = "github:treadiehq/port-kill"; flake = false; };
    termicons-font = { url = "file+https://termicons.mskelton.dev/termicons.ttf"; flake = false; };
    aptos-fonts = {
      url = "file+https://download.microsoft.com/download/8/6/0/860a94fa-7feb-44ef-ac79-c072d9113d69/Microsoft%20Aptos%20Fonts.zip";
      flake = false;
    };
    idevice-pair-release = {
      url = "file+https://api.github.com/repos/jkcoxson/idevice_pair/releases/latest";
      flake = false;
    };
  };
  outputs = inputs@{ nixpkgs, darwin, home-manager, nix-homebrew, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      lib = nixpkgs.lib;
      user = builtins.getEnv "DOTFILES_USER";
      username = if user == "" then "taekwondodev" else user;
      requestedHome = builtins.getEnv "DOTFILES_HOME";
      homeDirectory = if requestedHome == "" then "/Users/${username}" else requestedHome;
      declared = import ./nix/inventory.nix {
        inherit pkgs inputs system;
        npmSource = builtins.getEnv "DOTFILES_NPM_SOURCE";
        portKillLock = builtins.getEnv "DOTFILES_PORT_KILL_LOCK";
        piSource = builtins.getEnv "DOTFILES_PI_SOURCE";
        hermesVersion = builtins.getEnv "DOTFILES_HERMES_VERSION";
      };
      skipJSON = builtins.getEnv "DOTFILES_JAVA_SKIPS";
      dependencySkips = if skipJSON == "" then {} else builtins.fromJSON skipJSON;
      brewPolicyFile = builtins.getEnv "DOTFILES_BREW_POLICY";
      brewPolicy = if brewPolicyFile == "" then null else builtins.fromJSON (builtins.readFile brewPolicyFile);
      brewSkips = if brewPolicy == null then {} else brewPolicy.skipped;
      inventory = declared // {
        packages = builtins.removeAttrs declared.packages (builtins.attrNames dependencySkips);
        casks = builtins.removeAttrs declared.casks (builtins.attrNames brewSkips);
        manual = declared.manual // dependencySkips // brewSkips;
        pending = declared.pending ++ lib.optional (brewPolicy == null) "Homebrew source/metadata resolution";
      };
      agentConfig = import ./nix/agent-config.nix { inherit inputs inventory; };
      seeds = agentConfig.seeds // {
        ".hermes/config.yaml" = ./hermes/.hermes/config.yaml;
        ".hermes/SOUL.md" = ./hermes/.hermes/SOUL.md;
        ".hermes/profiles/apple-dev/config.yaml" = ./hermes/.hermes/profiles/apple-dev/config.yaml;
        ".hermes/profiles/apple-dev/profile.yaml" = ./hermes/.hermes/profiles/apple-dev/profile.yaml;
        ".hermes/profiles/apple-dev/SOUL.md" = ./hermes/.hermes/profiles/apple-dev/SOUL.md;
        ".hermes/profiles/apple-dev/assets/avatar.png" = ./hermes/.hermes/profiles/apple-dev/assets/avatar.png;
        ".hermes/profiles/wiki-dev/config.yaml" = ./hermes/.hermes/profiles/wiki-dev/config.yaml;
        ".hermes/profiles/wiki-dev/profile.yaml" = ./hermes/.hermes/profiles/wiki-dev/profile.yaml;
        ".hermes/profiles/wiki-dev/SOUL.md" = ./hermes/.hermes/profiles/wiki-dev/SOUL.md;
        ".hermes/profiles/wiki-dev/assets/avatar.png" = ./hermes/.hermes/profiles/wiki-dev/assets/avatar.png;
      };
      native = darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit inputs inventory username homeDirectory seeds agentConfig brewPolicy; };
        modules = [ home-manager.darwinModules.home-manager nix-homebrew.darwinModules.nix-homebrew ./nix/darwin.nix ];
      };
    in
    assert lib.assertMsg (username != "root" && builtins.match "[a-zA-Z0-9_][a-zA-Z0-9_.-]*" username != null) "Invalid target user";
    assert lib.assertMsg (lib.hasPrefix "/" homeDirectory && !(lib.hasInfix "\n" homeDirectory)) "Invalid home directory";
    assert lib.assertMsg (brewPolicy == null || (brewPolicy.core == toString inputs.homebrew-core && brewPolicy.cask == toString inputs.homebrew-cask)) "Homebrew metadata belongs to different tap inputs";
    {
      darwinConfigurations.fresh-mac = native;
      packages.${system}.bootstrap = import ./nix/runner.nix {
        inherit pkgs;
        brewCore = inputs.homebrew-core;
        brewCask = inputs.homebrew-cask;
        portKillSource = inputs.port-kill-source;
      };
      admissionManifest = native.config.system.build.dotfilesDestinationText;
      packageDerivations = lib.mapAttrs (_: package: package.drvPath) declared.packages;
      npmRequests = declared.npmRequests;
      piRelease = declared.piRelease;
      hermesRevision = declared.hermesRevision;
      caskRequests = declared.casks;
      caskDestinations = inventory.casks;
      homebrewSources = { core = toString inputs.homebrew-core; cask = toString inputs.homebrew-cask; };
      inventoryStatus = {
        packages = builtins.attrNames inventory.packages;
        casks = builtins.attrNames inventory.casks;
        inherit (inventory) manual pending;
      };
    };
}
