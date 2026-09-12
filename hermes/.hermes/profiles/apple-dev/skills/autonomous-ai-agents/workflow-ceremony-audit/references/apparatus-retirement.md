# Retiring a verification apparatus from a project repository

Use after the audit when the user asks to delete the campaign, choose one candidate, and carry the unresolved defect forward. Work on a throwaway branch, fast-forward into the main branch at the end.

## Order

1. **Inventory what is product and what is apparatus.** `git diff --stat <main> HEAD -- Sources Tests/<product>` versus `-- scripts Tests/Tooling docs .hermes Makefile`. List candidate branches, worktrees (`git worktree list`), installed candidate bundles, and evidence directories with `du -sh`.
2. **Stop processes before deleting bundles.** `pgrep -fl <app>` first; a candidate app left running keeps its executable mapped after `rm -rf` and confuses later process checks. Kill, wait, re-check, then delete the bundles and `git worktree remove --force` each worktree.
3. **Delete files with `git rm -r`**: apparatus scripts, their tests, verification docs, handoff files, project-local verify skills, harness executable targets. Remove the matching `.executableTarget` entries from `Package.swift` and the make targets plus `.PHONY` entries from the Makefile.
4. **Unwire instrumentation from product code with `patch`.** Follow the type outward: delete the recorder/observer type, then every constructor parameter, stored property, threaded identifier (`measurementID`-style fields on domain requests), and call site that only existed for it. Replace a measurement-stage return type with a small private enum when the callers still branch on it. `swift build` after each file group.
5. **Fix tests that imported the removed tree.** Grep `Tests/` for the deleted paths and for make-target names; a command-surface test that enumerates make targets and a test that `spec_from_file_location`s a deleted script both fail only at `make check`, not at `swift test`. Remove the test or the entry, and drop the file from any syntax-check list in the build tool.
6. **Write the ADR before the commit**: status, the observation that decided the verdict, the decision, what was removed, and an "Open defect carried forward" section holding facts, working hypothesis, and the sized route for the fix. The ADR is the only place the campaign's useful knowledge survives.
7. **Verify**: `make test`, `make check`, `make build`, `make verify`; then commit with one Conventional Commits subject, fast-forward the main branch, delete local and remote candidate/verification branches, push.
8. **Tracker**: close the campaign issues and the oversized parent spec with one short comment pointing at the ADR and commit; open one small issue for the carried defect with Observed, Expected line, Facts, Working hypothesis, Size. Ask before closing sibling issues whose subject vanished with the apparatus.

## Pitfalls

- Two candidates that fail identically under the same manual procedure settle the comparison by themselves: the varied dimension is not the cause. Say so plainly and pick the simpler one rather than proposing more measurement.
- `git rm` of a skill directory leaves a dangling symlink in the runtime skills dir when skills are stow-managed; remove it or the skill index keeps listing a dead entry.
- Keep opt-in, zero-cost diagnostics (unified-log records behind a launch flag) when they are the only tool for the open defect; delete instrumentation that writes evidence files.
