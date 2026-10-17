#!/usr/bin/env python3
"""Assemble the native app from Nix-owned inputs; never launch or sign it here."""
import json
from pathlib import Path
import plistlib
import shutil
import stat
import sys


def assemble(electron_app, desktop, source, identity_file, cli, version, app):
    identity = json.loads(identity_file.read_text())
    if (identity["productName"], identity["appId"], identity["executableName"]) != (
        "Hermes", "com.nousresearch.hermes", "Hermes"
    ):
        raise ValueError("Upstream Hermes identity changed; review the macOS adapter")
    # copytree refuses an occupied output. Never modify the input Electron.app.
    shutil.copytree(electron_app, app, symlinks=True)
    for path in [app, *app.rglob("*")]:
        if not path.is_symlink():
            path.chmod(path.stat().st_mode | stat.S_IWUSR)
    contents = app / "Contents"
    resources = contents / "Resources"
    info_file = contents / "Info.plist"
    info = plistlib.loads(info_file.read_bytes())
    if info["CFBundleExecutable"] != "Electron":
        raise ValueError("Unexpected Electron native executable")
    (contents / "MacOS/Electron").rename(contents / "MacOS/Hermes")
    info.update(identity["mac"]["extendInfo"])
    info.update({
        "CFBundleIdentifier": identity["appId"],
        "CFBundleExecutable": "Hermes",
        "CFBundleName": "Hermes",
        "CFBundleDisplayName": "Hermes",
        "CFBundleIconFile": "icon.icns",
        "CFBundleShortVersionString": version,
        "CFBundleVersion": version,
        "LSApplicationCategoryType": identity["mac"]["category"],
        "CFBundleURLTypes": [
            {"CFBundleURLName": protocol["name"], "CFBundleURLSchemes": protocol["schemes"], "CFBundleTypeRole": "Editor"}
            for protocol in identity["protocols"]
        ],
    })
    # The ICNS fallback must not resolve an unrelated Electron asset catalog.
    info.pop("CFBundleIconName", None)
    info_file.write_bytes(plistlib.dumps(info))
    helpers = list((contents / "Frameworks").glob("Electron Helper*.app"))
    if not helpers:
        raise ValueError("Electron helper bundles are missing")
    for helper in helpers:
        helper_info_file = helper / "Contents/Info.plist"
        helper_info = plistlib.loads(helper_info_file.read_bytes())
        name = helper.stem.replace("Electron", "Hermes", 1)
        executable = helper / "Contents/MacOS" / helper_info["CFBundleExecutable"]
        executable.rename(executable.with_name(name))
        role = helper.stem.removeprefix("Electron Helper").strip(" ()")
        helper_info["CFBundleExecutable"] = name
        helper_info["CFBundleVersion"] = version
        helper_info["CFBundleShortVersionString"] = version
        helper_info["CFBundleIdentifier"] = identity["appId"] + ".helper" + (f".{role}" if role else "")
        helper_info_file.write_bytes(plistlib.dumps(helper_info))
        helper.rename(helper.with_name(name + ".app"))
    shutil.copyfile(source / "apps/desktop/assets/icon.icns", resources / "icon.icns")
    shutil.copyfile(source / "LICENSE", resources / "Hermes-LICENSE")

    # A native executable plus a normal Resources/app layout preserves app
    # identity and relaunch. Its main module sets deployment policy before the
    # real ESM main executes; a shell wrapper around another .app would not.
    app_source = resources / "app"
    app_source.mkdir()
    manifest = json.loads((desktop / "package.json").read_text())
    manifest.update(name="Hermes", productName="Hermes", version=version, main="nix-main.mjs")
    (app_source / "package.json").write_text(json.dumps(manifest, indent=2) + "\n")
    for name, target in {
        "dist": desktop / "dist",
        "assets": source / "apps/desktop/assets",
        "public": source / "apps/desktop/public",
    }.items():
        # Gatekeeper rejects resource links escaping the bundle (TN2206).
        # These are built/public Nix inputs, never the installed app or its data.
        shutil.copytree(target, app_source / name)
    shutil.copyfile(desktop / "install-stamp.json", resources / "install-stamp.json")
    (app_source / "nix-main.mjs").write_text(
        f"process.env.HERMES_DESKTOP_HERMES = {json.dumps(str(cli))};\n"
        'process.env.HERMES_DISABLE_LAZY_INSTALLS = "1";\n'
        'process.env.ELECTRON_IS_DEV = "0";\n'
        # Electron requires awaited ESM imports before its ready event.
        'await import("./dist/electron-main.mjs");\n'
    )


if __name__ == "__main__":
    electron, desktop, source, identity, cli, version, app = sys.argv[1:]
    assemble(Path(electron), Path(desktop), Path(source), Path(identity), Path(cli), version, Path(app))
