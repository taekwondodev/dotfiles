# Fresh Apple Silicon Mac setup

This repository configures a fresh Apple Silicon Mac with nix-darwin and Home Manager. It is not a migration or backup of another machine: credentials, personal Git/SSH settings, browser profiles, Obsidian vaults, agent sessions, databases, caches and virtual-machine data are deliberately excluded.

## Implementation status

Nonempty `pending` entries (for example unresolved source metadata) block bootstrap activation; they are not manual exceptions. Do not treat the current configuration as a validated fresh installation.

Source evaluation and isolated fixtures do not establish package-build, installation, activation, managed-rerun or runtime correctness. The real macOS installation test is intentionally omitted at the user's request; the PR must disclose that omission.

## First install

Review `nix/inventory.nix` and its wiring in `flake.nix`, then run from this checkout once the inventory is complete:

```sh
./scripts/bootstrap.sh
```

The command rejects non-Apple-Silicon macOS, legacy Stow-linked destinations, and unmanaged existing configuration. It does not back up, adopt, overwrite, or remove them. Nix refreshes flake inputs on each deliberate run, builds the native configuration and applies it only after admission. Homebrew cleanup is disabled. Nix refreshes its tap sources once per deliberate run; Homebrew upgrades use those same immutable taps, without an independent auto-update. Service definitions are not automatically started.

Nix's initial installation uses the official Nix multi-user installer. This is a system-level operation. Do not run this setup on a machine whose existing configuration must remain untouched.

### Homebrew and native admission

Admission now checks the configured account's actual HOME, native system/per-user profiles, `/etc/static`, and the exact Homebrew management links declared by the preceding native generation. A copied marker or arbitrary store link is insufficient. Unreviewed `brew.env` overrides are refused because they can change source resolution. Known application, command, completion and man-page destinations are checked before activation; conflicting directories, links and Caskroom parents are not adopted. Cask ownership is read from the Caskroom receipt files without loading any cask, and a managed cask's stored `.metadata/config.json` must keep `/Applications` as its application directory, because Homebrew removes the previous version from there during an upgrade. Admission does not prove that an existing managed app bundle is still the copy Homebrew installed: if you replace it, a later upgrade backs it up into the Caskroom and then replaces it, as Homebrew normally does.

The dependency checker matches public Homebrew metadata to the Ruby files in the selected immutable taps and recursively checks declared cask/formula dependencies. A proven Java/Maven/Android conflict removes the requested owner from the automatic casks and adds its reason to the final manual report. Missing or mismatched metadata, new unsupported dependency footprints and opaque installer/hooks fail rather than becoming skips. The current ten automatic casks have no declared package dependencies.

Homebrew can also add unpacking tools required by the downloaded container format (for example `xz`, `zstd` or `p7zip`). These are archive utilities, never Java/Maven/Android, and the current casks ship as `.dmg` or `.zip`, which need none; they are therefore not separately guarded. The source checks above are not a guarantee about opaque binary contents or an executed installation.

## Update / retry

Run `./scripts/bootstrap.sh` again to refresh current upstream channels and reconcile this setup. Local app-owned settings are not intended to be overwritten.

The same command resumes an interrupted activation. Activation records its generation in the system profile (`/nix/var/nix/profiles/system`) only after every admission check and nix-darwin's own checks have passed, and before users, defaults, links, Homebrew or Home Manager change anything. A refusal by an admission check or by nix-darwin's checks records nothing; a step that fails after the record leaves a recorded, partly applied generation, which rerunning bootstrap resumes. Use bootstrap rather than `darwin-rebuild switch`, which records the generation before any check runs. A rerun then treats that recorded generation as an owner. Home Manager and native links are owned only when they point to the exact store paths of the active or a recorded generation. A cask is owned when the active or currently recorded generation declares it and Homebrew has a receipt for it. Older generations in the profile history never vouch for casks. Two gaps remain. A receipt cannot tell whether bootstrap or you installed a declared cask: if you install one of those casks with `brew` yourself after an interruption, the rerun manages it like its own. And if Home Manager stops partway through linking, a rerun can refuse the links it had already changed; remove the path named in each error and rerun, possibly several times.

`port-kill` and `port-kill-console` are declared as two binaries from the same upstream Rust source. A publisher-provided `Cargo.lock` is preserved. When absent, the runner resolves dependency metadata in an isolated temporary source copy before Nix consumes the lock. This technical lock is not committed. Their automatic update checks and self-update are disabled in the Nix build; neither binary is launched by bootstrap.

`dev` is reconstructed from its public source and publisher dependency lock, using Node 26 or later. Its matching Pi release comes from the version declared by dev and the official Pi release manifest/lock. Missing tarball hashes are read from that exact package version’s registry metadata into a separate technical file; upstream locks are not rewritten. Nix owns both launchers and disables Pi self-update/version checks. Update them through bootstrap, not dev’s source-checkout maintenance scripts.

Personal Pi settings and keybindings, bridge preferences, and dev’s `general`/`apple` profile guidance are writable seeds. Nix supplies the reviewed UI extensions, theme, Claude bridge source/dependencies and the four Apple profile skills. Device identifiers, changelog state, credentials, trust and sessions are not imported. Dev uses `~/.local/share/dev/profiles` and a writable data home under `~/Library/Application Support/dev/data`; installation-wide coordination stays in `~/Library/Application Support/dev/nix-installation`, outside the store and independent of `--data-home`. Existing `DEV_PROFILES` and `DEV_DATA_HOME` overrides remain available.

Hermes CLI uses its upstream Apple Silicon Nix package, retaining that project's Python/Node inputs and locks. Bootstrap resolves stable-tag version metadata for the exact selected source revision, rather than advertising upstream's placeholder `0.0.0` (which would reject compatible provider plugins). Nix retains update ownership; the local launchers disable on-demand dependency installation. Missing optional tools must be supplied deliberately, not repaired with a runtime installer.

`apple-dev` and `wiki-dev` select their Hermes profiles through the packaged CLI, forwarding arguments and leaving home/cwd selection to Hermes. The command surface includes `hermes` and `hermes-agent`, not the explicit ACP adapter or desktop app; upstream dependencies remain intact. Root and Apple profiles receive the public DirectSDK provider plugin with external Python ownership and the already-declared Claude Code executable. Credentials and service startup are not provisioned. Dormant service definitions are described below.

Hermes YAML/SOUL/avatar files are writable seeds. Personal skill/toolset selections and telemetry choices are retained; trust, onboarding/session state, excluded herdr/Figma integrations and machine-specific absolute paths are not. The sensitive-action hook keeps its original root-profile scope; named profiles do not inherit root hooks, and hook consent must be granted by the user. The wiki profile's working directory is `~/Developer/dotfiles`; its contents are not restored.

Hermes desktop is declared as `Hermes.app` under Home Manager's managed Applications tree, with `hermes-desktop` as its terminal entrypoint. It reuses the CLI's versioned upstream renderer and the exact Electron runtime/headers used to compile native modules. A native app bundle retains the Hermes identity, `hermes://` protocol, upstream privacy descriptions and ICNS icon. Its resources are copied from the Nix build outputs, not linked outside the bundle, as required by macOS signing rules; the installed app is never used as a source. Its entrypoint selects the Nix-owned CLI before the desktop main module loads; GUI launch does not depend on a shell profile. Desktop updates remain externally owned by Nix. Use this app/entrypoint rather than upstream's `hermes desktop` source-checkout build/maintenance command.

The declared macOS build uses ad-hoc signing of the generated app/helper bundles, with upstream entitlements: no personal signing identity, notarization, permission grant, login item or service activation. Existing app data is not copied. Ad-hoc signing does not promise permission grants will survive an update. Build/signature validation, Finder/Dock launch, relaunch, privacy prompts and native-module behavior have **not** been executed or verified under the source-only boundary.

HermesUsageMonitor is declared as a native menu-bar app in the same managed Applications tree. It requires macOS 26 or later and is built from its public source with Nix's Swift/SwiftPM, macOS SDK and `actool` catalog compiler, not the host Xcode installation. The bundled bridge uses the same sealed Python environment as Hermes CLI, resolving its actual package root rather than searching for a local checkout or virtualenv. `HERMES_HOME` and the upstream profile/data selection are preserved. Credentials, usage databases, app state and notification permissions are not copied; the app is not launched or registered as a login item. Quota refresh and notifications occur only when the user runs it; upstream's explicit manual-reset confirmation remains unchanged. Nix owns updates. Native build, catalog rendering, bridge/provider integration and notification behavior remain unverified. Its build declares ad-hoc signing after native fixups, without personal certificates or notarization.

## Claude Code

The existing Nix-owned executable receives a writable `~/.claude/settings.json` seed: `fable`, high effort for the selected Opus/Fable model IDs, automatic memory disabled, and empty commit/PR attribution. Later edits are preserved, not merged back into defaults on every bootstrap. The per-model effort format requires Claude Code 2.1.251 or later. Account access and model availability are not provisioned.

The public skills input supplies its `skills/` tree at `~/.agents/skills` and individual immutable links at `~/.claude/skills/<name>`. The parent Claude skill directory stays writable for additional personal skills and Claude.ai sync; `synced` is reserved for Claude, not managed by Nix. An existing unmanaged skill directory is refused, never adopted or replaced. If dependency policy omits Claude Code, its seed and personal skill links are omitted too; shared skills remain available to other agents.

Workspace-specific `autoMode` trust context, credentials, approvals, sessions and caches are not imported. The excluded herdr hook and empty Stop callback are not reproduced. No personal plugin selection was found to restore; default catalog metadata, builtin-plugin UI state and stale local skill aliases are not configuration sources. Plugins and account sync remain app-owned; bootstrap neither installs plugins nor runs hooks or Claude itself. The package disables the binary self-updater, but retains upstream packaging's plugin-update behavior.

Evaluation and fixtures do not verify real skill discovery, Claude's settings writes, account/model access, consent or plugin sync. Complete login and any required consent manually when choosing to use the managed installation.

## Lavagna

One Nix package supplies the Go `lavagna` CLI and its Swift notification helper, `Lavagna.app` (macOS 13 or later). The browser UI and font assets remain embedded in the CLI, with MIT and SIL OFL notices retained. Nix supplies both compilers, the SDK and icon-conversion tools; the bundle preserves upstream identity, artwork and the Apple Events privacy description. Ad-hoc signing is declared after native fixups, without personal certificates.

Home Manager provides `~/Applications/Lavagna.app` as an explicit link to that same package, because the unmodified CLI requires this exact helper location. The managed Applications tree exposes the same bundle, not a second installation. Admission refuses an existing unmanaged app or a replaced managed link; nothing is adopted, moved or deleted. If the package is excluded by dependency policy, its explicit link is omitted too.

Neither `make install` nor the upstream notifier installer is run. Bootstrap does not register/open the app or request notification/Automation permissions. When you choose to authorize notifications on the fresh managed installation, the upstream entrypoint is `open -g "$HOME/Applications/Lavagna.app" --args authorize`. Normal later use can also request consent. Notifications contain fixed text, not question content; clicking tries to focus an existing Chrome tab, requiring Automation access broader than that one tab. Refusing that access leaves the default-browser fallback available.

The root Hermes writable seed already includes `lavagna hermes-hook` for terminal results and session end. Its original scope and first-use consent remain; no hook installer or live config command is executed. Conversation caches, transcripts, browser data and permissions are not restored. Lavagna retains its upstream trusted-account/local-browser security model, including documented WebRTC limits; it is not a sandbox for untrusted content. Native builds, upstream Go tests, icon rendering, notification delivery, LaunchServices attribution and click handling through the managed app link remain unverified.

## Monitor Volume

Monitor Volume is built from its public SwiftPM source into `Monitor Volume.app` in Home Manager’s managed Applications tree. It requires macOS 15 or later. Nix supplies Swift/SwiftPM and the macOS SDK; the original artwork is converted to ICNS using Nix-owned ImageMagick/libicns tools. Bundle identity, privacy descriptions and license notices are preserved. The build declares ad-hoc signing after native fixups, without personal certificates or notarization. The upstream installer is not used: it also stops, replaces and launches applications.

Bootstrap neither launches the app nor grants permissions or registers a login item. **The app itself attempts login-item registration once on its first manual launch**, preserving upstream behavior; macOS System Settings remains its management surface. No preferences or registration-attempt marker are imported or reset. The app has no Dock or menu-bar icon. Its media-key interception requires Accessibility permission; ad-hoc-signed updates may require renewed Accessibility and Local Network authorization.

While running, upstream advertises a Bonjour TCP listener for Volume Up, Volume Down and Mute. It has **no pairing, authentication or encryption**: devices on the same LAN can send those keys. The iOS companion is not provisioned. Monitor control uses private IOKit/IOAVService interfaces whose compatibility Apple does not guarantee. Native build/signing, icon rendering, hardware control, networking, permission attribution and login registration from the managed app location remain unverified under the source-only boundary.

## Manual Hermes services

Home Manager supplies two reviewed plists under `~/.local/share/dotfiles/services`: `ai.hermes.gateway.plist` and `com.hermes.claude-subscription-directsdk-env.plist`. Nothing is placed in `Library/LaunchAgents`, registered, started or loaded at a later login by bootstrap. `RunAtLoad` applies only if you manually register a definition. The directory participates in the normal managed-file admission checks; it is not an adoption path for existing services.

The gateway runs the packaged Hermes CLI through its upstream timestamp/signal wrapper, with explicit external supervision and no forced process replacement. It restarts failures but parks a clean stop or fatal configuration refusal. Its environment names the managed profile and Claude executable directly, so it does not depend on the session-environment job starting first. Credentials and gateway configuration must be supplied separately before you choose to start it.

**Privacy difference:** the definition does not use upstream's `osascript` platform-identity workaround for macOS Local Network Privacy. A directly launched Python service may be denied LAN access. No privacy grant or bypass is provisioned; service registration, networking, drain/restart and provider behavior are unverified. These examples were not executed during development.

On the fresh managed Mac only, review both files and inspect `launchctl print "gui/$(id -u)/<label>"` for each intended label first. If a label already exists, do not replace or unload it without establishing its ownership. To explicitly start the gateway in your current GUI login session:

```sh
services="$HOME/.local/share/dotfiles/services"
domain="gui/$(id -u)"
mkdir -p "$HOME/.hermes/logs"
launchctl bootstrap "$domain" "$services/ai.hermes.gateway.plist"
```

The separate DirectSDK job sets `CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND` in the **session-wide launchd environment** for subsequently launched GUI processes. It is not required for the gateway. Before opting in, record whether `launchctl getenv CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND` already has a value; loading this job replaces that value. Then explicitly load its plist with `launchctl bootstrap "$domain" "$services/com.hermes.claude-subscription-directsdk-env.plist"`. Existing processes do not inherit the change.

Use `launchctl bootout "$domain/<label>"` to unload only a job you deliberately registered. Unloading the environment job does **not** undo `setenv`: restore the recorded value with `launchctl setenv`, or use `launchctl unsetenv CLAUDE_SUBSCRIPTION_DIRECTSDK_COMMAND` only if it was previously absent. These definitions are not persistent login items; registration must be requested again in a new login session.

A Nix refresh updates the dormant plists, not already loaded jobs or session environment values. Explicitly unload/reload your own jobs from the reviewed new files when ready, before garbage-collecting their previous package paths. Do not use `hermes gateway install` to manage these definitions: its installer owns a different, automatically discovered LaunchAgents path.

## TeX to PDF

One Nix-owned TeX Live environment provides XeLaTeX and pdfLaTeX, `latexmk`, common LaTeX packages and fonts, English/Italian language support, BibTeX, BibLaTeX/Biber and `makeindex`. It replaces the broad medium scheme with the basic scheme plus selected additions; unrelated TeX GUI tools and the Java-dependent extras are not selected. Core TeX support programs can still be included as dependencies: this is a focused compilation environment, not a claim of the smallest possible closure.

For a document compatible with the chosen engine, use one of these commands on the future managed installation:

```sh
latexmk -xelatex document.tex
latexmk -pdf document.tex
```

`latexmk` handles the necessary compilation passes, including bibliography/index processing when required by the document. Package coverage is not universal: declare additional document-specific packages in the `tex` selection in `nix/inventory.nix`, rather than using `tlmgr` or a second TeX installer to mutate the Nix-owned environment. Updates follow the same deliberate Nix refresh as the rest of the setup.

TeXstudio and standalone TeX GUI apps are excluded by owner choice. No existing TeX installation or application is removed, and no documents, bibliography databases, GUI preferences, caches or machine-local TeX trees are copied. No personal source additions were found in the inspected standard TeX locations. Package/format evaluation does not validate real PDF output, font rendering, bibliography/index correctness or compatibility with private documents; the commands above were not executed during development.

## Raycast

The Raycast application remains installed by the existing Homebrew cask. **Personalization is a named manual exception, not an automated restore.** Configure your desired preferences and shortcuts in [Settings](https://manual.raycast.com/settings), and choose extensions through the [Store](https://manual.raycast.com/extensions) when you decide to use the fresh installation. Bootstrap does not start Raycast, sign in, register shortcuts/login items, grant permissions or install extensions.

Raycast v2's documented [Import & Export](https://manual.raycast.com/import-export) flow creates a passphrase-encrypted `.rayconfig` containing settings and extensions alongside chats, clipboard history, notes, MCP configuration and other private data. This is not a settings-only source suitable for this repository. No reviewed standalone personal configuration is supplied here; copying window/onboarding markers, the app's SDK symlink or its internal databases would not reproduce it safely. Nothing from those locations is restored.

This setup does not require a backup, export, Cloud Sync or passphrase. Do not commit a `.rayconfig` file or put its passphrase in Nix. If you independently choose to transfer an existing private export, Raycast offers category-selective import, but that alone is not proof that settings or extension data contain no credentials or approvals. Review such a transfer separately; the setup neither performs nor validates it. Login, licensing, permissions, personal values and extension behavior remain manual and unverified.

## Manual exceptions

The runner reports exceptions declared in `manual` in `nix/inventory.nix`. Explicit owner choices and evidence-backed licensing, manual-install or legitimate-source restrictions qualify. Unknown or unimplemented work remains pending, not skipped. Automatic installer failures are failures, not skips. Complete account, licensing, SDK/simulator, extension and service setup yourself as applicable. Service definitions are not authorization to activate or start them.

**Logi Options+, Microsoft Teams, SF Symbols and OrbStack are installed manually by owner choice.** Bootstrap does not install or update them, run their vendor/pkg/postflight procedures, or claim their application paths. Existing installations remain untouched. At successful completion, the terminal summary prints **`MANUAL ACTION REQUIRED (not performed by bootstrap):`**, followed by every manual component and its instructions from the inventory, including these four. This is a terminal reminder, not a macOS desktop notification, and does not detect whether you have already completed a manual step.

VMware Fusion requires manual installation through an authorized Broadcom account: Homebrew removed its cask because downloads require authentication. This is a source-access exception, not an exclusion of VMware or a failure silently treated as success. No virtual machines or data are restored.

Xcode itself remains a manual installation, including license acceptance and SDK/simulator selection. **All Xcode personalization is excluded by owner choice**, not deferred restoration: no themes, keybindings, snippets, templates or Xcode-specific preferences are installed. Existing Xcode configuration is neither claimed nor modified by this setup.

## Configuration ownership

Home Manager owns the reviewed Fish, Ghostty, Neovim, Starship and Vim configuration links. Hermes, Pi and Claude Code app-authored configuration uses writable seeds; reruns preserve edits. Nix owns tool installation and Neovim external tools; Mason does not install tools independently. Personal runtime state is not copied from an existing machine. The existing files remain in their original languages.

Linux, Intel, server and Stow installation modes have been removed. Vapor toolbox, SwiftPlantUML CLI/app, OpenLogi (including its customizations) and TeXstudio are explicitly excluded by owner choice, not deferred manual installations. Logi Options+ remains the only included Logitech controller, installed manually. No OpenLogi configuration is installed or restored. Excluded programs and their existing configuration are never removed from a host.
