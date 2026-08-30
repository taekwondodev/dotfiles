# Stale app icon in macOS notifications (menu bar apps)

## Symptom

A long-lived menu bar app with a **stable bundle id** (reinstalled many times) shows an
outdated app icon in its notifications even though the `AppIcon` in the installed bundle is
current. The user says "the very first app icon appears in notifications, not the current one".

## Root cause

This is macOS icon caching keyed by bundle-id, not a code bug. The bundle id
(`com.<dev>.<App>`) never changed across reinstalls, so LaunchServices / the icon-services
store keep rendering the first icon they registered for that id. The notification adapter
uses the platform's own app icon automatically; it does not set a custom image. Changing the
asset catalog and rebuilding does nothing because the OS serves the cached icon.

## Confirm before doing anything

- One copy of the `.app` installed (ignore duplicate `find` hits from overlapping maxdepth).
- The built bundle's `AppIcon.icns` is current (extract its largest PNG and compare visually
  with the source `AppIcon.appiconset/*.png`).
- The menu bar mark (a separate `HermesMenuBarIcon`-style image) is NOT the app icon; an
  "H in ring" mark can live only as the menu bar icon while the app icon is something else.

## Fix (safe, no app code change)

```sh
# 1. Force LaunchServices re-registration (also refresh its icon).
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREG" -f "$APP"

# 2. Drop the user icon-services cache (exact path varies per machine).
#    Find it: find /private/var/folders -maxdepth 5 -name "com.apple.iconservices*"
#    e.g. /var/folders/<xx>/<hash>/C/com.apple.iconservices/store.index
#    and tint-color-registry.map — remove both.
rm -f /var/folders/.../com.apple.iconservices/store.index \
      /var/folders/.../com.apple.iconservices/tint-color-registry.map

# 3. Restart NotificationCenter (safe; it auto-restarts).
killall NotificationCenter

# 4. Re-register once more so the icon is re-read from the bundle.
"$LSREG" -f "$APP"
```

Confirmation comes from the next real notification; there is no reliable instant probe.

## Notes

- `com.apple.ncprefs.plist` in `~/Library/Preferences` holds notification prefs, not icons;
  the icon is resolved via LaunchServices / icon-services.
- Do NOT "fix" the asset catalog for this symptom; if the bundle icon is already current the
  catalog is fine.
- This is the standard macOS remedy for stale notification icons across reinstallations of an
  unchanged bundle id.