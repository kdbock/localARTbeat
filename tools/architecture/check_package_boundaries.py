#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path

from package_graph import REPO_ROOT, SIBLING_PREFIX, iter_package_pubspecs, parse_sibling_dependencies

IMPORT_PATTERN = re.compile(
    r"""^\s*(?:import|export)\s+['"]package:(artbeat_[a-z_]+)/(.*?)['"]""",
)


def iter_dart_files(package_root: Path) -> list[Path]:
    return sorted(
        path
        for root in (package_root / "lib", package_root / "test")
        for path in (root.rglob("*.dart") if root.exists() else [])
        if "build" not in path.parts
        and path.parts[-2] != "generated"
        and not path.name.endswith(".mocks.dart")
    )


def main() -> int:
    violations: list[str] = []

    for pubspec_path in iter_package_pubspecs():
        package_root = pubspec_path.parent
        package_name = package_root.name
        allowed_siblings = set(parse_sibling_dependencies(pubspec_path))
        allowed_siblings.add(package_name)

        for dart_file in iter_dart_files(package_root):
            rel_path = dart_file.relative_to(REPO_ROOT)
            in_triple_single = False
            in_triple_double = False

            for line_number, line in enumerate(dart_file.read_text().splitlines(), start=1):
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
                    violations.append(
                        f"{rel_path}:{line_number}: cross-package src import/export is forbidden: {imported_package}/{imported_path}"
                    )
                    continue

                if imported_package not in allowed_siblings:
                    violations.append(
                        f"{rel_path}:{line_number}: missing pubspec dependency for sibling package '{imported_package}'"
                    )

    if violations:
        print("Package boundary check failed.")
        print(
            "Rules: lib/ must not import another package's src/ internals, and every sibling package import must be declared in pubspec.yaml."
        )
        print("")
        for violation in violations:
            print(violation)
        return 1

    print("Package boundary check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
