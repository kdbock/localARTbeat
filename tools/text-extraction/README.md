# Text Extraction Artifacts

This folder holds historical text-extraction inputs and outputs that were
previously stored at the repo root.

## Contents

- `data/`
  - extracted translation JSON files
  - supporting key lists
  - dependency/output artifacts from text-analysis work

## Intent

These files are useful for reference and migration work, but they are not part
of the app runtime and should not live at the project root.

If a script still expects a root-relative path, update the script or pass an
explicit output path rather than moving these files back.
