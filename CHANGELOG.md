# Changelog

All notable changes to this repository's tooling and manifests are documented in this file.

## [Unreleased] - 2026-11-28

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
