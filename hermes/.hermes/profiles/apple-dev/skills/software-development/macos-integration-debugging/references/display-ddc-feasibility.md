# External-display DDC feasibility

Use this recipe after discovery identifies the selected audio output and its physical display. Keep probes disposable and outside the repository; proving hardware feasibility is not implementing automatic target selection.

## 1. Establish the current binding

- Query `system_profiler SPAudioDataType -json` for the default output and `ioreg -a -l -w 0` for display product attributes and external DDC service endpoints. Filter before printing; do not dump unrelated audio devices or serials.
- Correlate the display framebuffer and external proxy using observed endpoint relationships. On Apple Silicon, matching `dispextN` names in the framebuffer branch and proxy endpoint branch can provide evidence for the current topology; do not assume the proxy is a framebuffer descendant or rely only on enumeration order.
- When guarding a probe with an IORegistry entry ID, revalidate its identity and path immediately before access. IDs captured earlier are not durable device identities.
- Compare paths using their actual API representation. `IORegistryEntryGetPath` includes unit addresses such as `dispextN@...`, whereas joining `IORegistryEntryName` values from a plist can omit them. Derive checks from observed paths and identity fields rather than loosening a failed guard blindly.

## 2. Probe each capability independently

- Reuse the inspected application's transport helpers in a small C probe where practical; compile with `xcrun clang`, the transport include directory, and `-framework CoreFoundation -framework IOKit`. Add `-framework CoreAudio` when checking the live default output inside the probe.
- Query volume with Get VCP `0x62` and mute with Get VCP `0x8D` separately. A Get request sends an I2C request packet but does not change the monitor setting; distinguish it from Set VCP.
- Inspect response framing, echoed code, result byte, checksum, current value, and maximum. For a valid Get VCP reply, result byte `0x01` indicates unsupported VCP; do not report it as transient malformed data merely because the existing adapter merges these outcomes.
- Retry transient or malformed reads a small bounded number of times before declaring incompatibility. Preserve both failed and successful observations. If needed, inspect raw protocol bytes to distinguish explicit unsupported responses from transport failures; a known-readable capability such as brightness `0x10` can be queried as a control without changing brightness.
- Do not infer write support from successful reads, or generic range support from a monitor returning maximum 100.

## 3. Exercise an authorized reversible write

1. Recheck default output, physical identity, and exact endpoint. Abort before any Set VCP if the topology changed or the recipient is ambiguous.
2. Read the target's current volume and another connected monitor's volume as a non-target baseline. Never assume a remembered starting value.
3. Lower the target by the smallest safe nonzero amount within its reported range. If already at zero, stop rather than increasing output without agreement.
4. Read back the target and non-target immediately. Require the intended target change and unchanged non-target state; a successful transport return alone is not proof.
5. Restore the captured target value even if the write result or intermediate read is inconclusive. Use bounded restore attempts, read back the restoration, and report any failure explicitly.
6. Print a compact before/during/restored table and return failure unless target change, isolation, and restoration were all verified. Do not retain hardcoded live IDs in production code.

This verifies setting control and isolation in the observed topology. Audible effect may still require a user check; automatic routing and rebinding require their own implementation and lifecycle acceptance. Avoid turning a reversible personal-utility probe into an unnecessary permanent verification framework.
