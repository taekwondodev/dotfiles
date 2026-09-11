# Transactional macOS app install and rollback

Use this reference when a script assembles, replaces, launches, or rolls back a locally installed `.app` bundle.

## Invariants

- The staged candidate is fully assembled, signed, and verified before the installed bundle is touched.
- Capture the bound executable digest only after final bundle signing, because `codesign` can mutate the Mach-O.
- When a campaign promises an exact prepared-to-installed binding, retain the entire signed bundle and install a byte-for-byte copy without invoking `codesign` again.
- Process termination matches the exact absolute executable path. A display name, bundle name, or broad process-name match is insufficient.
- For side-by-side candidates with distinct identities, validate the installed bundle identity, retained executable digest, metadata digest, and designated requirement immediately before signaling or removal. Refuse on mismatch and never fall back to the production identity; path ownership alone does not prove campaign ownership.
- The previous installed bundle becomes the backup only after it has been verified.
- Rollback validates the backup before any destructive action.
- In the narrower transactional-replacement threat model, rollback does not validate the failed candidate because corruption may be the reason rollback is running; this exception applies only to the exact install path owned by that transaction and a prevalidated backup.
- A failed or unusable backup preserves the current installed path for diagnosis rather than deleting it.

## Install ordering

1. Reconcile any prior backup without overwriting an unverified path.
2. Verify the currently installed bundle when present.
3. Build and fully verify a staged candidate.
4. Stop only the exact installed executable.
5. Rename the installed bundle to the backup path.
6. Rename the staged candidate to the installed path.
7. Launch and verify the installed candidate.
8. Remove the backup only after the new candidate is proven.

Keep the rename and launch operations inside the rollback-protected region. Record whether the old app was running so successful rollback can restore its lifecycle state.

## Rollback ordering

1. When replacement was intended, require the backup path and reject symlinks.
2. Fully verify the backup, including directory shape, metadata, executable, and signature. Allow only explicitly supported compatibility exceptions, such as notices introduced after the backup version.
3. Stop a candidate process by the exact installed executable path without verifying the candidate bundle.
4. Remove the failed candidate.
5. Rename the verified backup to the installed path.
6. Relaunch and verify it when the previous app was running.

The key asymmetry is deliberate: trust must be established for the artifact being restored, while the artifact being removed may be malformed.

## Regression probes

Run probes in an isolated temporary installation root. Use a copy of a real signed bundle when signature verification is part of the contract.

- Signing boundary: hash the raw SwiftPM executable, assemble and sign the bundle, and prove that the post-signing executable is the artifact that must be frozen.
- Designated-requirement framing: test both `designated => …` and `# designated => …` arriving on either stdout or stderr, plus duplicate/missing rejection; do not bind parsing to one macOS release's diagnostic stream.
- Prepared-install identity: copy the retained signed bundle through the real staging/rename path and assert the prepared and installed executable bytes and hashes are identical; a mock that skips signing proves only filesystem behavior.
- Side-by-side production isolation: install two temporary candidate identities, attempt a mismatched identity or digest at stop/cleanup, and prove the operation refuses without signaling or modifying the production identity.
- Bound cleanup: force failure immediately after launch and prove exact-path cleanup still reaches zero processes even when the caller has not yet received the successful install result.
- Valid backup plus corrupt candidate: rollback restores the backup and consumes the backup path.
- Missing backup: rollback fails before removal and preserves the current bundle.
- Symlink backup: rollback fails before removal and preserves the current bundle.
- Regular-file backup: rollback fails before removal and preserves the current bundle.
- Corrupt-directory backup: rollback fails before removal and preserves the current bundle.
- Backup-creation rename failure: the original installed bundle remains untouched.
- Candidate launch or verification failure: the verified backup is restored.
- Running candidate: only the exact candidate executable is terminated.

After the isolated probes, exercise the repository's real build and verify commands against the installed Release artifact. Compilation or a mocked filesystem alone does not prove the transaction.
