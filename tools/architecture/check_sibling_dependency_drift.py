#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path

from package_graph import SIBLING_PREFIX, iter_package_pubspecs, parse_sibling_dependencies
IMPORT_PATTERN = re.compile(
    r"""^\s*(?:import|export)\s+['"]package:(artbeat_[a-z_]+)/(.*?)['"]""",
)


def collect_used_siblings(package_root: Path, package_name: str) -> set[str]:
    used: set[str] = set()

    for scope in ("lib", "test"):
        scope_root = package_root / scope
        if not scope_root.exists():
            continue

        for dart_file in scope_root.rglob("*.dart"):
            if "build" in dart_file.parts or dart_file.name.endswith(".mocks.dart"):
                continue

            in_triple_single = False
            in_triple_double = False
            for line in dart_file.read_text().splitlines():
                single_toggle_count = line.count("'''")
                double_toggle_count = line.count('"""')

                if not in_triple_double and single_toggle_count % 2 == 1:
                    in_triple_single = not in_triple_single
                if not in_triple_single and double_toggle_count % 2 == 1:
                    in_triple_double = not in_triple_double

                if in_triple_single or in_triple_double:
                    continue

                match = IMPORT_PATTERN.match(line)
                if not match:
                    continue

                imported_package, imported_path = match.groups()
                if imported_package == package_name:
                    continue
                if imported_path.startswith("src/"):
                    continue
                used.add(imported_package)

    return used


def main() -> int:
    drift_found = False

    for pubspec_path in iter_package_pubspecs():
        package_root = pubspec_path.parent
        package_name = package_root.name
        declared = set(parse_sibling_dependencies(pubspec_path))
        used = collect_used_siblings(package_root, package_name)

        extra = sorted(declared - used)
        if extra:
            drift_found = True
            print(f"{package_name}: stale sibling dependencies declared but unused: {', '.join(extra)}")

    if drift_found:
        print("")
        print("Sibling dependency drift check failed.")
        print("Remove stale sibling package entries from pubspec.yaml or reintroduce their real usage intentionally.")
        return 1

    print("Sibling dependency drift check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
