# Package Residue Audit

## Purpose

Track unusual package-local project artifacts that are not normal for this
workspace and decide whether they should be removed, archived, or kept.

## Findings

### `packages/artbeat_admin/.git`

Status:

- resolved: removed accidental untracked nested Git repository
- approximately 80K
- contains only standard local Git metadata
- no remote configured in `config`

Assessment:

- almost certainly accidental local residue
- not part of app runtime
- should not live inside the main repo

Recommended action:

- completed

Risk:

- low for app/runtime
- moderate for local developer history if someone intentionally used it

### `packages/artbeat_profile/ios`

Status:

- tracked iOS project scaffold inside a Flutter package that is not declared as
  a plugin
- approximately 476K
- contains a `Runner` app target with bundle identifier
  `com.example.artbeatProfile`
- includes tracked Xcode project files plus ignored generated/Pods output

Assessment:

- looks like an embedded standalone Flutter/iOS app scaffold rather than a
  required part of the package
- nothing else in the repo references it directly
- removing it would be a tracked-source deletion and should be treated as
  higher risk

Recommended action:

- do not remove as part of opportunistic cleanup
- verify no one still relies on this package-local iOS scaffold
- if confirmed unused, remove in a dedicated cleanup change with validation

Risk:

- medium because files are tracked and historical intent is unclear

## Cleanup Rule

- nested untracked repos may be removed only in cleanup-focused work
- tracked package-local project scaffolds require explicit review before removal
