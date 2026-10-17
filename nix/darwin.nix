{ config, lib, pkgs, inputs, inventory, username, homeDirectory, seeds, agentConfig, brewPolicy, ... }:
let
  home = config.home-manager.users.${username};
  links = map (file: "link\t${file.target}") (lib.filter (file: file.enable) (builtins.attrValues home.home.file));
  seedEntries = lib.mapAttrsToList (target: _: "seed\t${target}") seeds;
  destinations = pkgs.writeText "dotfiles-destinations" (lib.concatStringsSep "\n" (links ++ seedEntries) + "\n");
  casks = pkgs.writeText "dotfiles-casks.json" (builtins.toJSON inventory.casks);
  caskArtifacts = pkgs.writeText "dotfiles-cask-artifacts.json" (builtins.toJSON (if brewPolicy == null then {} else brewPolicy.artifacts));
  brewSetupClosure = pkgs.closureInfo {
    rootPaths = [ (pkgs.writeText "dotfiles-brew-setup-reference" config.system.activationScripts.setup-homebrew.text) ];
  };
  brewLinks = pkgs.runCommand "dotfiles-brew-links" {} ''
    bash ${./homebrew-links.sh} ${brewSetupClosure}/store-paths > "$out"
  '';
  caskCheck = ''
    (
      PATH=${pkgs.jq}/bin:$PATH
      # shellcheck source=/dev/null
      source ${./admission.sh}
      # shellcheck source=/dev/null
      source ${./native-admission.sh}
      # shellcheck source=/dev/null
      source ${./cask-admission.sh}
      recorded=$(dotfiles_generations ${lib.escapeShellArg homeDirectory} ${builtins.storeDir} /run/current-system /nix/var/nix/profiles/system)
      dotfiles_admit_casks "$recorded" /Applications /opt/homebrew ${casks} ${caskArtifacts}
    )
  '';
  admissionCheck = ''
    # shellcheck source=/dev/null
    source ${./admission.sh}
    generations=$(dotfiles_generations ${lib.escapeShellArg homeDirectory} ${builtins.storeDir} /run/current-system /nix/var/nix/profiles/system /nix/var/nix/profiles/system-*-link)
    dotfiles_admit ${lib.escapeShellArg homeDirectory} "$generations" ${builtins.storeDir} ${./protected-roots} ${destinations}
  '';
in {
  system.stateVersion = 6;
  system.primaryUser = username;
  users.users.${username} = { home = homeDirectory; shell = pkgs.fish; };
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc.automatic = false;
  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      "com.apple.swipescrolldirection" = false;
      "com.apple.trackpad.scaling" = 0.6875;
    };
    dock = {
      orientation = "bottom";
      autohide = false;
      tilesize = 66;
      persistent-apps = [
        "/System/Applications/Calendar.app" "/System/Applications/Notes.app"
        "/Applications/Safari.app" "/System/Applications/Mail.app"
        "/Applications/Ghostty.app" "/System/Applications/System Settings.app"
      ];
    };
    finder = { ShowPathbar = true; FXPreferredViewStyle = "Nlsv"; };
    trackpad = { TrackpadThreeFingerDrag = false; TrackpadRightClick = true; Clicking = false; };
    CustomUserPreferences."com.apple.HIToolbox".AppleSelectedInputSources = [
      { InputSourceKind = "Keyboard Layout"; "KeyboardLayout ID" = 223; "KeyboardLayout Name" = "Italian - Pro"; }
    ];
  };

  nix-homebrew = {
    enable = true;
    user = username;
    enableRosetta = false;
    autoMigrate = false;
    mutableTaps = false;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
  };
  homebrew = {
    enable = true;
    onActivation = { autoUpdate = false; upgrade = true; cleanup = "none"; };
    casks = builtins.attrNames inventory.casks;
  };
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    enableLegacyProfileManagement = false;
    extraSpecialArgs = { inherit inventory inputs username homeDirectory seeds admissionCheck agentConfig; };
    users.${username} = import ./home.nix;
  };

  # All declared Nix GUI packages use Home Manager's guarded application link.
  # Do not run nix-darwin's redundant /Applications/Nix Apps rsync --delete
  # copier or its legacy-link cleanup against an unrelated application tree.
  system.activationScripts.applications.text = lib.mkForce "";

  # Guard the system boundary as well as HM's file boundary. In nix-darwin this
  # hook precedes users/defaults/launchd/Homebrew and the eventual HM activation.
  system.activationScripts.homebrew.text = lib.mkBefore caskCheck;
  system.activationScripts.preActivation.text = admissionCheck + ''
    source ${./native-admission.sh}
    dotfiles_admit_account ${lib.escapeShellArg username} ${lib.escapeShellArg homeDirectory}
    dotfiles_admit_native ${lib.escapeShellArg homeDirectory} ${lib.escapeShellArg username} "$generations" /private/etc /nix/var/nix/profiles/system /opt/homebrew
  '' + caskCheck + lib.optionalString (brewPolicy != null) ''
    if [[ $(/usr/bin/sw_vers -productVersion) != ${lib.escapeShellArg brewPolicy.osVersion} ]]; then
      echo 'Homebrew metadata resolved for a different macOS version; rerun bootstrap.' >&2
      exit 1
    fi
  '' + ''
    if [[ ${toString (builtins.length inventory.pending)} != 0 ]]; then
      echo 'Refusing incomplete configuration; unresolved inventory is not a manual skip.' >&2
      exit 1
    fi
  '';
  # Record this generation only after the admissions above and nix-darwin's own
  # checks have passed (check mode exits there), and before users, defaults,
  # links, Homebrew or Home Manager change anything: a refused activation
  # records nothing, and a later interruption leaves its partial state owned.
  system.activationScripts.extraActivation.text = lib.mkBefore ''
    ${config.nix.package}/bin/nix-env --profile /nix/var/nix/profiles/system --set "$systemConfig"
  '';
  system.systemBuilderCommands = ''
    mkdir -p "$out/dotfiles"
    printf '%s\n' ${lib.escapeShellArg "taekwondodev/dotfiles:${homeDirectory}"} > "$out/dotfiles/identity"
    ln -s ${home.home.activationPackage} "$out/dotfiles/home-manager"
    ln -s ${destinations} "$out/dotfiles/destinations"
    ln -s ${casks} "$out/dotfiles/casks.json"
    ln -s ${caskArtifacts} "$out/dotfiles/cask-artifacts.json"
    ln -s ${brewLinks} "$out/dotfiles/homebrew-links"
  '';
  system.build.dotfilesDestinations = destinations;
  system.build.dotfilesDestinationText = lib.concatStringsSep "\n" (links ++ seedEntries) + "\n";
}
