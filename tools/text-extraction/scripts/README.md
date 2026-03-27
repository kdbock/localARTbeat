# Text Extraction Scripts

These scripts support one-off or historical translation/text extraction work.

Current rule:

- outputs should go under `tools/text-extraction/data/`
- do not create new root-level data artifacts from these scripts

These scripts are not part of the production app runtime.

Useful command:

- `python3 tools/text-extraction/scripts/extract_english_text.py`

Current output files for the untranslated-UI scan:

- `tools/text-extraction/data/probable_untranslated_screen_text.md`
- `tools/text-extraction/data/probable_untranslated_screen_text.json`

The markdown report now also includes:

- `Top Repeated Literals` for the most common hardcoded strings
- `Batch Candidates` for literals that appear at least 3 times

This is intended to make cleanup batchable instead of forcing file-by-file review.
