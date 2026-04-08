# Cloud Functions Entrypoints

## Canonical Deploy Entrypoint

- Firebase deploy source: `functions/` (from [`firebase.json`](/Volumes/ExternalDrive/DevProjects/artbeat/firebase.json))
- Node package main: [`functions/package.json`](/Volumes/ExternalDrive/DevProjects/artbeat/functions/package.json) -> `"main": "src/index.js"`
- Canonical exported functions file: [`functions/src/index.js`](/Volumes/ExternalDrive/DevProjects/artbeat/functions/src/index.js)

## Ownership

- Primary owner: backend/functions remediation stream.
- Any new Cloud Function exports must be added in `src/index.js`.
- Legacy standalone entrypoint files must not be reintroduced in the `functions/` root.

## Legacy Archive

Historical entrypoint variants were moved to:

- [`functions/archive/legacy_entrypoints`](/Volumes/ExternalDrive/DevProjects/artbeat/functions/archive/legacy_entrypoints)

These files are retained for historical reference only and are not part of deployment.
