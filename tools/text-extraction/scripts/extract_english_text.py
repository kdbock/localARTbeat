#!/usr/bin/env python3
"""Report probable hardcoded UI text in Dart files."""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


ROOT_MARKERS = ("lib", "packages")
SKIP_PARTS = {
    ".dart_tool",
    "build",
    "ios",
    "android",
    "linux",
    "macos",
    "windows",
    "web",
    "test",
}
SKIP_SUFFIXES = (".g.dart", ".freezed.dart", ".gr.dart", ".mocks.dart")
SKIP_NAME_PREFIXES = ("debug_",)
NOISE_PATTERNS = (
    re.compile(r"^\$[A-Za-z_]\w*:?$"),
    re.compile(r"^\$[A-Za-z_]\w*\s*\(\$[A-Za-z_]\w*\)$"),
    re.compile(r"^\$[A-Za-z_]\w*:\s*\$[A-Za-z_]\w*$"),
    re.compile(r"^\$[A-Za-z_]\w*:\s*\$\{[^}]+\}$"),
    re.compile(r"^\$\{[^}]+\}%$"),
    re.compile(r"^\$\{[^}]+\}$"),
    re.compile(r"^\$[A-Za-z_]\w*%$"),
)


@dataclass(frozen=True)
class PatternSpec:
    name: str
    regex: re.Pattern[str]


PATTERNS = [
    PatternSpec(
        "Text widget",
        re.compile(
            r"""\bText\s*\(\s*(?P<quote>['"])(?P<text>(?:\\.|(?!\1).)+)(?P=quote)(?!\s*\.tr\s*\()""",
            re.MULTILINE | re.DOTALL,
        ),
    ),
    PatternSpec(
        "Button or label text",
        re.compile(
            r"""\b(?:title|label|child|tooltip|semanticLabel)\s*:\s*Text\s*\(\s*(?P<quote>['"])(?P<text>(?:\\.|(?!\1).)+)(?P=quote)(?!\s*\.tr\s*\()""",
            re.MULTILINE | re.DOTALL,
        ),
    ),
    PatternSpec(
        "Input decoration string",
        re.compile(
            r"""\b(?:labelText|hintText|helperText|counterText|errorText)\s*:\s*(?P<quote>['"])(?P<text>(?:\\.|(?!\1).)+)(?P=quote)(?!\s*\.tr\s*\()""",
            re.MULTILINE | re.DOTALL,
        ),
    ),
    PatternSpec(
        "SnackBar or dialog text",
        re.compile(
            r"""\b(?:content|message)\s*:\s*Text\s*\(\s*(?P<quote>['"])(?P<text>(?:\\.|(?!\1).)+)(?P=quote)(?!\s*\.tr\s*\()""",
            re.MULTILINE | re.DOTALL,
        ),
    ),
    PatternSpec(
        "Tab text",
        re.compile(
            r"""\bTab\s*\([^)]*\btext\s*:\s*(?P<quote>['"])(?P<text>(?:\\.|(?!\1).)+)(?P=quote)(?!\s*\.tr\s*\()""",
            re.MULTILINE | re.DOTALL,
        ),
    ),
]


def is_probable_ui_text(text: str) -> bool:
    candidate = text.strip()
    if len(candidate) < 2:
        return False
    if "\n" in candidate:
        return False
    if not re.search(r"[A-Za-z]", candidate):
        return False
    if candidate.startswith("package:") or candidate.startswith("dart:"):
        return False
    if candidate.startswith("http://") or candidate.startswith("https://"):
        return False
    if candidate.endswith(".dart"):
        return False
    if re.fullmatch(r"[a-z0-9_.]+", candidate):
        return False
    if re.fullmatch(r"[A-Z0-9_]+", candidate):
        return False
    if ".tr(" in candidate or candidate.endswith(".tr()"):
        return False
    if any(pattern.fullmatch(candidate) for pattern in NOISE_PATTERNS):
        return False
    return True


def file_should_be_scanned(path: Path) -> bool:
    path_str = path.as_posix()
    if not path_str.endswith(".dart"):
        return False
    if any(part in SKIP_PARTS for part in path.parts):
        return False
    if path.name.endswith(SKIP_SUFFIXES):
        return False
    if path.name.startswith(SKIP_NAME_PREFIXES):
        return False
    return any(path_str == marker or path_str.startswith(f"{marker}/") for marker in ROOT_MARKERS)


def load_dart_files(root: Path) -> list[Path]:
    files = [path for path in root.rglob("*.dart") if file_should_be_scanned(path.relative_to(root))]
    return sorted(files)


def line_number_for_offset(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def trimmed_single_line(text: str) -> str:
    return " ".join(text.strip().split())


def extract_context(content: str, start: int, end: int, radius: int = 80) -> str:
    snippet = content[max(0, start - radius) : min(len(content), end + radius)]
    return trimmed_single_line(snippet)


def scan_file(root: Path, path: Path) -> list[dict[str, object]]:
    content = path.read_text(encoding="utf-8")
    findings: list[dict[str, object]] = []
    seen: set[tuple[int, str]] = set()
    rel_path = path.relative_to(root).as_posix()

    for spec in PATTERNS:
        for match in spec.regex.finditer(content):
            text = trimmed_single_line(match.group("text"))
            if not is_probable_ui_text(text):
                continue
            line = line_number_for_offset(content, match.start())
            fingerprint = (line, text)
            if fingerprint in seen:
                continue
            seen.add(fingerprint)
            findings.append(
                {
                    "file": rel_path,
                    "line": line,
                    "text": text,
                    "pattern": spec.name,
                    "context": extract_context(content, match.start(), match.end()),
                }
            )

    findings.sort(key=lambda item: (int(item["line"]), str(item["text"])))
    return findings


def group_for_report(findings_by_file: dict[str, list[dict[str, object]]]) -> dict[str, dict[str, list[dict[str, object]]]]:
    grouped: dict[str, dict[str, list[dict[str, object]]]] = defaultdict(dict)
    for file_path, findings in findings_by_file.items():
        if file_path.startswith("packages/"):
            group = file_path.split("/")[1]
        else:
            group = "main_app"
        grouped[group][file_path] = findings
    return dict(sorted(grouped.items()))


def package_counts(findings_by_file: dict[str, list[dict[str, object]]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for file_path, findings in findings_by_file.items():
        if file_path.startswith("packages/"):
            group = file_path.split("/")[1]
        else:
            group = "main_app"
        counts[group] += len(findings)
    return counts


def text_counts(findings_by_file: dict[str, list[dict[str, object]]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for findings in findings_by_file.values():
        for finding in findings:
            counts[str(finding["text"])] += 1
    return counts


def generate_markdown(findings_by_file: dict[str, list[dict[str, object]]], scanned_files: int) -> str:
    grouped = group_for_report(findings_by_file)
    total_findings = sum(len(items) for items in findings_by_file.values())
    text_counter = text_counts(findings_by_file)
    unique_text = sorted(text_counter)

    lines: list[str] = []
    lines.append("# Probable Untranslated Screen Text")
    lines.append("")
    lines.append(f"*Generated: {datetime.now().isoformat(timespec='seconds')}*")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append(f"- Dart files scanned: {scanned_files}")
    lines.append(f"- Files with probable hardcoded UI text: {len(findings_by_file)}")
    lines.append(f"- Findings: {total_findings}")
    lines.append(f"- Unique text values: {len(unique_text)}")
    lines.append("")
    lines.append("This report flags probable user-visible text literals in widgets and input decoration properties.")
    lines.append("It does not prove a string is wrong; it is a review queue for localization cleanup.")
    lines.append("")
    lines.append("## Top Packages")
    lines.append("")
    for package_name, count in package_counts(findings_by_file).most_common(10):
        lines.append(f"- {package_name}: {count}")
    lines.append("")
    lines.append("## Top Files")
    lines.append("")
    top_files = sorted(
        findings_by_file.items(),
        key=lambda item: (-len(item[1]), item[0]),
    )[:20]
    for file_path, findings in top_files:
        lines.append(f"- {file_path}: {len(findings)}")
    lines.append("")
    lines.append("## Top Repeated Literals")
    lines.append("")
    for text, count in text_counter.most_common(25):
        lines.append(f"- `{text}`: {count}")
    lines.append("")
    lines.append("## Batch Candidates")
    lines.append("")
    batch_candidates = [
        (text, count) for text, count in text_counter.most_common() if count >= 3
    ][:40]
    if batch_candidates:
        for text, count in batch_candidates:
            lines.append(f"- `{text}`: {count}")
    else:
        lines.append("- No repeated literals above the current batch threshold.")
    lines.append("")

    for group_name, files in grouped.items():
        group_total = sum(len(items) for items in files.values())
        lines.append(f"## {group_name} ({group_total})")
        lines.append("")
        for file_path, findings in sorted(files.items()):
            lines.append(f"### {file_path} ({len(findings)})")
            lines.append("")
            for finding in findings:
                lines.append(
                    f"- Line {finding['line']}: `{finding['text']}` [{finding['pattern']}]"
                )
            lines.append("")

    lines.append("## Unique Text")
    lines.append("")
    for text in unique_text:
        lines.append(f"- `{text}`")
    lines.append("")
    return "\n".join(lines)


def generate_json(findings_by_file: dict[str, list[dict[str, object]]], scanned_files: int) -> dict[str, object]:
    text_counter = text_counts(findings_by_file)
    return {
        "metadata": {
            "generated_at": datetime.now().isoformat(timespec="seconds"),
            "scanned_files": scanned_files,
            "files_with_findings": len(findings_by_file),
            "findings": sum(len(items) for items in findings_by_file.values()),
            "unique_text_values": len(
                {str(item["text"]) for items in findings_by_file.values() for item in items}
            ),
            "top_packages": package_counts(findings_by_file).most_common(10),
            "top_files": sorted(
                ((file_path, len(items)) for file_path, items in findings_by_file.items()),
                key=lambda item: (-item[1], item[0]),
            )[:20],
            "top_repeated_literals": text_counter.most_common(25),
            "batch_candidates": [
                (text, count) for text, count in text_counter.most_common() if count >= 3
            ][:40],
        },
        "files": findings_by_file,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Find probable untranslated UI text in Dart files")
    parser.add_argument("--root", default=".", help="Repository root")
    parser.add_argument(
        "--output",
        default="tools/text-extraction/data/probable_untranslated_screen_text.md",
        help="Markdown report output path",
    )
    parser.add_argument(
        "--json",
        default="tools/text-extraction/data/probable_untranslated_screen_text.json",
        help="JSON report output path",
    )
    args = parser.parse_args()

    root = Path(args.root).resolve()
    files = load_dart_files(root)
    findings_by_file: dict[str, list[dict[str, object]]] = {}

    print(f"Scanning {len(files)} Dart files")
    for path in files:
        findings = scan_file(root, path)
        if findings:
            findings_by_file[path.relative_to(root).as_posix()] = findings

    output_path = root / args.output
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(generate_markdown(findings_by_file, len(files)), encoding="utf-8")

    json_path = root / args.json
    json_path.parent.mkdir(parents=True, exist_ok=True)
    json_path.write_text(
        json.dumps(generate_json(findings_by_file, len(files)), indent=2, ensure_ascii=False),
        encoding="utf-8",
    )

    print(f"Markdown report: {output_path}")
    print(f"JSON report: {json_path}")
    print(f"Files with findings: {len(findings_by_file)}")
    print(f"Total findings: {sum(len(items) for items in findings_by_file.values())}")


if __name__ == "__main__":
    main()
