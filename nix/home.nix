{ config, lib, pkgs, inventory, username, homeDirectory, seeds, admissionCheck, agentConfig, ... }:
{
  home = {
    inherit username homeDirectory;
    stateVersion = "26.05";
    packages = lib.unique (builtins.attrValues inventory.packages);
    sessionVariables.EDITOR = "nvim";
    # Driver v1's current-home GC root is part of our native ownership proof.
    activationGenerateGcRoot = true;
    file = (lib.mapAttrs (_: source: { inherit source; }) agentConfig.files) // {
      ".config/ghostty/config".source = ../ghostty/.config/ghostty/config;
      ".config/nvim".source = ../nvim/.config/nvim;
      ".vimrc".source = ../vim/.vimrc;
      ".hermes/agent-hooks/block-sensitive.sh" = {
        source = ../hermes/.hermes/agent-hooks/block-sensitive.sh;
        executable = true;
      };
    } // lib.optionalAttrs (inventory.packages ? lavagna) {
      # The upstream CLI resolves this exact path. This is an alias to the same
      # immutable package, not a second copy or a takeover of an existing app.
      "Applications/Lavagna.app".source = "${inventory.packages.lavagna}/Applications/Lavagna.app";
    } // (import ./manual-services.nix {
      inherit lib homeDirectory;
      profileDirectory = config.home.profileDirectory;
      hermes = inventory.packages.hermes-cli or null;
      claude = inventory.packages.claude-code or null;
    });
    activation = {
      dotfilesAdmission = lib.hm.dag.entryBefore [ "checkLinkTargets" "writeBoundary" ] admissionCheck;
      dotfilesSeeds = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.concatStringsSep "\n" (lib.mapAttrsToList (target: source: ''
          destination=${lib.escapeShellArg "${homeDirectory}/${target}"}
          if [[ ! -e "$destination" ]]; then
            dotfiles_plain_parents ${lib.escapeShellArg homeDirectory} "$(dirname "$destination")"
            run mkdir -p -- "$(dirname "$destination")"
            if [[ ! -v DRY_RUN ]]; then
              # noclobber refuses a file appearing after admission, instead of
              # silently adopting it or truncating the user's configuration.
              (umask 077; set -o noclobber; cat ${lib.escapeShellArg source} > "$destination")
            fi
          fi
        '') seeds)
      );
    };
  };
  # One immutable application-tree link, rather than a copier that could
  # overwrite or remove unrelated applications from a writable directory.
  targets.darwin.linkApps.enable = true;
  targets.darwin.copyApps.enable = false;
  xdg.enable = true;
  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ../fish/.config/fish/config.fish;
  };
  programs.starship = {
    enable = true;
    enableFishIntegration = false; # The preserved personal Fish file initializes it.
    settings = builtins.fromTOML (builtins.readFile ../starship/.config/starship.toml);
  };
  fonts.fontconfig.enable = true;
}
