# Changelog

All notable changes to this repository's tooling and manifests are documented in this file.

## [0.002] - 2026-11-28

### Fixed

- `bin/Update-AutoupdateManifests.ps1`
  - Honor the `-Manifests` parameter: only the requested manifest(s) are checked instead of
    always scanning the whole bucket.
  - Honor the `-BucketDir` parameter: `checkver.ps1` is now called directly with
    `-Dir $BucketDir` (and manifests are resolved from it) instead of relying on the
    hard-coded `..\bucket` path in the `bin\checkver.ps1` wrapper.
  - Stop hiding failures with an unconditional `exit 0`. Failed autoupdates, `git add`,
    `git commit` and `git push` now set a failure flag, and the script exits with code `1`.
  - The `git pull` guard (review item 1) was already fixed in `0.001`; no further change
    was needed for this round.

## [0.001] - 2026-11-28

### Fixed

- `bin/Update-AutoupdateManifests.ps1`
  - Pin the autoupdate to the version returned by the initial check by calling
    `checkver.ps1 <app> -Update -Version <version>`. This removes the redundant second
    network request and prevents the committed version from drifting away from the version
    that triggered the update.
  - Manifests whose `autoupdate` block references `$match*` variables (for example
    `$matchTag` or `$matchCodename`) are still re-checked with a full
    `checkver.ps1 <app> -Update`, because those variables are only populated by a full check.
  - Read the version back from the updated manifest before committing, so the commit message
    always matches what was actually written to the file.
  - Use `git pull --ff-only` and abort the run when it fails, instead of a plain `git pull`
    that could create merge commits or leave the repository in a conflicted state.
  - Fix the `git pull` guard: `-not $GITPULLED | Out-Null` always evaluated to `$false`, so
    the pull never ran. The pull now executes once before the first update.
