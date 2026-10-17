{ lib, homeDirectory, profileDirectory, hermes, claude }:
let
  hermesHome = "${homeDirectory}/.hermes";
  claudeEnvironment = lib.optionalAttrs (claude != null) {
    CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND = "${claude}/bin/claude";
  };
  definitions = lib.optionalAttrs (hermes != null) {
    "ai.hermes.gateway" = {
      Label = "ai.hermes.gateway";
      # Keep upstream timestamping, signal forwarding and fatal-exit parking.
      # No osascript/platform-identity workaround for macOS privacy checks.
      ProgramArguments = [
        "${hermes.runtime.hermesVenv}/bin/python3" "-m" "hermes_cli.stderr_timestamp"
        "--error-log" "${hermesHome}/logs/gateway.error.log" "--"
        "${hermes}/bin/hermes" "gateway" "run" "--external-supervisor"
      ];
      WorkingDirectory = hermesHome;
      EnvironmentVariables = {
        HOME = homeDirectory;
        HERMES_HOME = hermesHome;
        HERMES_SUPERVISED_CHILD = "1";
        HERMES_DISABLE_LAZY_INSTALLS = "1";
        PYTHONDONTWRITEBYTECODE = "1";
        PATH = "${profileDirectory}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      } // claudeEnvironment; # No ordering dependency on the session-env job.
      LimitLoadToSessionType = [ "Aqua" "Background" ];
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
      ExitTimeOut = 60;
      SoftResourceLimits.NumberOfFiles = 4096;
      StandardOutPath = "${hermesHome}/logs/gateway.log";
      StandardErrorPath = "${hermesHome}/logs/gateway.error.log";
    };
  } // lib.optionalAttrs (claude != null) {
    "com.hermes.claude-subscription-directsdk-env" = {
      Label = "com.hermes.claude-subscription-directsdk-env";
      ProgramArguments = [
        "/bin/launchctl" "setenv" "CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND"
        claudeEnvironment.CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND
      ];
      RunAtLoad = true;
    };
  };
in
# This directory is NOT searched by launchd, including at the next login.
# These are Home Manager files, never launchd.agents or launchd.daemons.
lib.mapAttrs' (label: definition: lib.nameValuePair
  ".local/share/dotfiles/services/${label}.plist"
  { text = lib.generators.toPlist { escape = true; } definition; }
) definitions
