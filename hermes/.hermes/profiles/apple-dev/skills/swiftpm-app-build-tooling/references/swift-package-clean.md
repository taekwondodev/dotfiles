# Verifying `swift package clean` never touches the installed app

Danger: users assume a `clean` target cleans the delivered `.app`. Before shipping one
bound to `swift package clean`, prove empirically that it only touches `.build`.

## Why it's safe

`swift package clean` removes SwiftPM's build-artifact directory (`.build/`) only. It
does not touch `~/Applications`. The `.app` bundle in `~/Applications` is produced by a
separate script (`build-app.sh`) and is entirely independent of `.build`. mtime and
signature are unchanged across a clean.

## The verification commands (run in the package root)

```bash
# 1) Baseline
# project-root/.build size (e.g. 428M) and installed executable mtime:
du -sh .build
stat -f '%Sm' "$HOME/Applications/<App>.app/Contents/MacOS/<App>"

# 2) Execute the clean
swift package clean

# 3) Confirm .build is emptied (428M -> ~4K, or removed)
du -sh .build

# 4) Installed app mtime must be IDENTICAL to baseline
stat -f '%Sm' "$HOME/Applications/<App>.app/Contents/MacOS/<App>"

# 5) Signature must still verify
codesign --verify --deep --strict "$HOME/Applications/<App>.app" && echo STILL_SIGNED
```

## Expected result (measured in HermesUsageMonitor)

| Check | Before | After |
|-------|--------|-------|
| `.build` | 428M | 4.0K |
| installed executable mtime | Aug 23 00:38:04 | Aug 23 00:38:04 (identical) |
| `codesign --verify --deep --strict` | — | STILL_SIGNED |

## Note

Clearing `.build` forces the next `make build` to do a full release rebuild. That is
expected and normal — do not treat a following slower build as a regression.