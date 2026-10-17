{ pkgs, source, lockFile }:
pkgs.rustPlatform.buildRustPackage {
  pname = "port-kill";
  version = (builtins.fromTOML (builtins.readFile (source + "/Cargo.toml"))).package.version;
  src = source;
  cargoLock.lockFile = lockFile;
  cargoBuildFlags = [ "--bin" "port-kill" "--bin" "port-kill-console" ];
  # Upstream runtime tests start services and inspect host state. Packaging must
  # only produce the executables; it must not run this process-control utility.
  doCheck = false;
  env.PORT_KILL_NIX_MANAGED = "1";
  postPatch = ''
    if [ ! -f Cargo.lock ]; then
      cp ${lockFile} Cargo.lock
    fi
    # Compile-time ownership cannot be bypassed by changing the runtime env.
    # Reject explicit updater flags before the GUI or other CLI actions start.
    substituteInPlace src/main.rs src/main_console.rs \
      --replace-fail 'let mut args = Args::parse();' \
        'let mut args = Args::parse();
          if option_env!("PORT_KILL_NIX_MANAGED").is_some() && (args.check_updates || args.self_update) {
              anyhow::bail!("Updates are managed by Nix; rerun scripts/bootstrap.sh from the dotfiles checkout.");
          }'
    substituteInPlace src/update_check.rs \
      --replace-fail \
        'pub async fn check_for_updates(current_version: &str) -> Result<Option<UpdateInfo>> {' \
        'pub async fn check_for_updates(current_version: &str) -> Result<Option<UpdateInfo>> {
          if option_env!("PORT_KILL_NIX_MANAGED").is_some() {
              anyhow::bail!("Updates are managed by Nix; rerun scripts/bootstrap.sh from the dotfiles checkout.");
          }' \
      --replace-fail \
        'pub async fn self_update() -> Result<()> {' \
        'pub async fn self_update() -> Result<()> {
          if option_env!("PORT_KILL_NIX_MANAGED").is_some() {
              anyhow::bail!("Updates are managed by Nix; rerun scripts/bootstrap.sh from the dotfiles checkout.");
          }'
  '';
  postInstall = ''
    test -x "$out/bin/port-kill"
    test -x "$out/bin/port-kill-console"
  '';
  meta.platforms = [ "aarch64-darwin" ];
}
