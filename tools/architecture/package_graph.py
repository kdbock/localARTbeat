#!/usr/bin/env python3

from __future__ import annotations

from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
PACKAGES_DIR = REPO_ROOT / "packages"
SIBLING_PREFIX = "artbeat_"


def iter_package_pubspecs() -> list[Path]:
    return sorted(PACKAGES_DIR.glob("*/pubspec.yaml"))


def parse_sibling_dependencies(pubspec_path: Path) -> list[str]:
    dependencies: list[str] = []
    in_dependencies = False

    for raw_line in pubspec_path.read_text().splitlines():
        line = raw_line.rstrip()
        stripped = line.strip()

        if not stripped or stripped.startswith("#"):
            continue

        if not raw_line.startswith(" ") and stripped.endswith(":"):
            in_dependencies = stripped == "dependencies:"
            continue

        if not in_dependencies:
            continue

        if raw_line.startswith("  ") and not raw_line.startswith("    "):
            name = stripped.split(":", 1)[0].strip()
            if name.startswith(SIBLING_PREFIX):
                dependencies.append(name)

    return dependencies


def build_dependency_graph() -> dict[str, list[str]]:
    return {
        pubspec_path.parent.name: parse_sibling_dependencies(pubspec_path)
        for pubspec_path in iter_package_pubspecs()
    }


def feature_dependencies(graph: dict[str, list[str]], package_name: str) -> list[str]:
    return [
        dependency
        for dependency in graph[package_name]
        if dependency != "artbeat_core"
    ]


def high_coupling_packages(graph: dict[str, list[str]], minimum_feature_dependencies: int = 2) -> list[str]:
    return [
        package_name
        for package_name in sorted(graph)
        if len(feature_dependencies(graph, package_name)) >= minimum_feature_dependencies
    ]


def mutual_coupling_pairs(graph: dict[str, list[str]]) -> list[tuple[str, str]]:
    pairs: list[tuple[str, str]] = []

    for package_name, dependencies in sorted(graph.items()):
        for dependency in dependencies:
            if dependency <= package_name:
                continue
            if package_name in graph.get(dependency, []):
                pairs.append((package_name, dependency))

    return pairs
