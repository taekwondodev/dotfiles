{ inputs, inventory }:
let
  skills = inputs.skills + "/skills";
  claudeSkills = builtins.listToAttrs (map (name: {
    name = ".claude/skills/${name}";
    value = skills + "/${name}";
  }) (builtins.filter (name:
    # Claude owns this namespace for account-synced skills.
    name != "synced" && builtins.pathExists (skills + "/${name}/SKILL.md")
  ) (builtins.attrNames (builtins.readDir skills))));
in
{
  # Individual paths leave auth, sessions, trust and mutable preferences
  # writable and outside Home Manager. Never link the whole agent directory.
  files = {
    ".agents/skills" = skills;
    ".pi/agent/themes/rose-pine-moon.json" = ../agents/pi/agent/themes/rose-pine-moon.json;
    ".pi/agent/extensions/dev-agent-sound.ts" = ../agents/pi/agent/extensions/dev-agent-sound.ts;
    ".pi/agent/extensions/dev-final-reply-bg.ts" = ../agents/pi/agent/extensions/dev-final-reply-bg.ts;
    ".pi/agent/extensions/terminal-status-title.js" = ../agents/pi/agent/extensions/terminal-status-title.js;
    ".pi/agent/extensions/calm" = ../agents/pi/agent/extensions/calm;
    ".pi/agent/extensions/hud-footer" = ../agents/pi/agent/extensions/hud-footer;
    ".local/share/dev/profiles/apple/skills/swiftui-pro" = inputs.swiftui-skill + "/swiftui-pro";
    ".local/share/dev/profiles/apple/skills/swift-concurrency-pro" = inputs.swift-concurrency-skill + "/swift-concurrency-pro";
    ".local/share/dev/profiles/apple/skills/swift-testing-pro" = inputs.swift-testing-skill + "/swift-testing-pro";
    ".local/share/dev/profiles/apple/skills/swiftdata-pro" = inputs.swiftdata-skill + "/swiftdata-pro";
  } // (if inventory.packages ? claude-code then claudeSkills else {})
  // (if inventory.packages ? pi-claude-bridge then {
    # Stable path in settings, updated by Nix with the extension's dependencies.
    ".local/share/dev/pi-claude-bridge" = "${inventory.packages.pi-claude-bridge}/lib/node_modules/pi-claude-bridge";
  } else {}) // (if inventory.packages ? hermes-cli then {
    # Hermes discovers user plugins in each profile, not in the root profile.
    ".hermes/plugins/claude-subscription-directsdk-experimental" = inventory.packages.hermes-cli.providerPlugin;
    ".hermes/profiles/apple-dev/plugins/claude-subscription-directsdk-experimental" = inventory.packages.hermes-cli.providerPlugin;
  } else {});
  seeds = {
    ".pi/agent/settings.json" = ../agents/pi/agent/settings.json;
    ".pi/agent/keybindings.json" = ../agents/pi/agent/keybindings.json;
    ".pi/agent/claude-bridge.json" = ../agents/pi/agent/claude-bridge.json;
    ".local/share/dev/profiles/manifest.json" = ../agents/dev/profiles/manifest.json;
    ".local/share/dev/profiles/general/SOUL.md" = ../agents/dev/profiles/general/SOUL.md;
    ".local/share/dev/profiles/apple/SOUL.md" = ../agents/dev/profiles/apple/SOUL.md;
  } // (if inventory.packages ? claude-code then {
    ".claude/settings.json" = ../agents/claude/settings.json;
  } else {});
}
