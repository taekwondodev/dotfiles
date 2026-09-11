# External-display volume over DDC/CI

Use this reference when a native macOS menu-bar utility controls monitor speakers through DDC/CI rather than software audio attenuation.

## Capability-first probe

Do not infer volume support merely because the monitor advertises DDC/CI. Verify the exact monitor and feature against the live connection.

1. Inspect display and audio routing with `system_profiler SPDisplaysDataType SPAudioDataType`; confirm whether USB-C is carrying DisplayPort Alt Mode and whether the monitor is the active output.
2. Inspect stable display metadata in IORegistry: product name, manufacturer, EDID, serial when present, connection location, and whether a display service user interface is exposed.
3. Use a disposable DDC CLI probe or a minimal throwaway probe—without installing a GUI utility—to list displays and read volume.
4. Select the display by its stable system/EDID identity. A list index, `CGDirectDisplayID`, and a DDC tool's selector can be different values.
5. Read current and maximum volume.
6. Write the current value back unchanged, then read it again. This proves the write path while producing no intentional audible change.
7. Probe mute separately.

A successful session established this reusable baseline on an Apple Silicon Mac with a USB-C/DisplayPort monitor:

- volume read and same-value write/read-back succeeded;
- maximum volume was 100;
- mute was independently readable;
- selecting by a transient numeric display ID failed while selecting by stable UUID succeeded.

## MCCS/VCP features

Common monitor-control feature codes:

- `0x62`: speaker volume;
- `0x8D`: audio mute.

Treat these as protocol conventions, not guarantees. Read capability and verify behavior on the target firmware. Keep raw VCP values inside the DDC adapter and expose typed domain values such as bounded volume and mute state.

## Implementation boundaries

Keep four concerns separate:

1. **Display identity:** resolves the intended monitor from stable EDID/system attributes.
2. **DDC transport:** serializes I2C/DDC requests, retries only according to an explicit policy, and confirms writes by read-back.
3. **Audio routing:** determines whether the target monitor is the active Core Audio output.
4. **Interaction:** conditionally consumes volume-up, volume-down, and mute events; otherwise passes them through unchanged.

The UI should display only confirmed hardware state. During slider drags, coalesce writes rather than flooding the DDC bus, but make the final committed position read-back verified.

## Apple Silicon and distribution constraints

On Apple Silicon, USB-C/DisplayPort DDC implementations commonly use IOAVService I2C entry points because legacy framebuffer I2C paths do not apply. These are not a supported public App Store API. Isolate them in one adapter so macOS updates have a narrow compatibility surface.

A native macOS volume OSD likewise generally requires a non-public system interface. Keep it behind a feedback port so a SwiftUI overlay can replace it without changing volume logic.

## OSD semantic verification and fallback

Do not treat a matching private selector ABI, a successful invocation, or a visible HUD as proof that the supplied external volume is rendered. On newer macOS releases, the private volume OSD may ignore `filledChiclets`/`totalChiclets` and instead display unrelated Core Audio state.

Verify at least zero, a low positive value, and a mid-range value on the installed Release artifact. If the displayed fill does not track confirmed DDC state, replace the private OSD with a non-activating app-owned `NSPanel` hosting SwiftUI. Present only after the Service publishes a confirmed active-output result; keep AppKit/SwiftUI ownership in the Handler layer.

For a zero-safe custom meter, do not rely on a native linear `ProgressView`: some macOS styles render a minimum cap at zero. Draw the groove and conditionally omit the fill at zero. If a discrete step rail accompanies the bar, derive both from one inset geometry (typically the bar cap centers), place the 20 five-point ticks at positions 5...100, and give only the current tick the strongest emphasis. Validate the geometry visually at 0, 5, a middle value, and 100.

## Media-key interception and TCC

Global observation is not enough when the app must prevent macOS from also handling the key. A modifying `CGEventTap` is typically needed for `NX_SYSDEFINED` media-key events.

- Preflight/request ListenEvent access where applicable.
- Expect Input Monitoring and possibly Accessibility approval depending on tap location/options and OS behavior.
- Consume events only while the intended monitor is the active audio output; pass all other events through.
- Handle `.tapDisabledByTimeout` and `.tapDisabledByUserInput` by re-enabling the tap.
- Verify callback delivery after signing and Launch Services launch; a non-nil event tap is not proof that it is receiving events.
- Keep callback work bounded. Route DDC work to a serialized service rather than blocking the event-tap callback.

## Compound volume/unmute semantics

Some monitors implicitly leave hardware mute when volume is written, but the volume write's read-back confirms only volume. Reusing the pre-write mute value then publishes a contradictory snapshot: the first key press changes hardware while the UI remains muted until the next refresh.

Treat a volume key pressed while confirmed-muted as one serialized Service intent: read current state, write/read back the adjusted volume, explicitly write/read back unmute, then publish one combined confirmed snapshot. Add a regression test that asserts both adapter operations and the final volume+mute state. Keep partial-failure behavior explicit: if the second write fails, report command failure rather than fabricating a fully confirmed state.

## Failure semantics

- On read failure, distinguish disconnected, unsupported, permission denied, transport failure, and malformed reply where evidence permits.
- On write failure, retain the last fully confirmed value and show an error; do not leave an optimistic slider value presented as hardware truth.
- If the target is not active, do not consume the media key.
- If target presence was known but the asynchronous DDC write later fails, surface the failure; the consumed key cannot be retroactively passed back to macOS.
