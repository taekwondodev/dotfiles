#!/usr/bin/env python3
"""Classify declared packages from Nix's evaluated derivation graph; never build."""
import hashlib
import json
import re
import sys
from pathlib import Path, PurePosixPath
from urllib.parse import quote
from urllib.request import urlopen

FORBIDDEN = re.compile(
    r"(^|[-_.])(?:openjdk|jdk|jre|openj9|temurin|corretto|graalvm|zulu|"
    r"oraclejdk|adoptopenjdk|liberica|sapmachine|maven|jdtls|google-java-format|"
    r"android-(?:sdk|ndk|studio|platform-tools|commandlinetools|tools)|androidsdk|androidstudio)"
    r"(?=$|[-_.0-9])", re.IGNORECASE
)


def classify(packages, document):
    # Nix <=2.33 used full-path keys/inputDrvs; current Nix wraps a graph whose
    # store-relative keys use inputs.drvs. Require either known representation.
    records = document.get("derivations", document)
    if not isinstance(records, dict) or not records:
        raise ValueError("empty/unsupported Nix derivation graph")
    graph = {}
    for path, record in records.items():
        key = PurePosixPath(path).name
        if "inputs" in record:
            dependencies = record["inputs"]["drvs"]
        else:
            dependencies = record["inputDrvs"]
        name = record.get("name", record.get("env", {}).get("name", key.split("-", 1)[-1]))
        graph[key] = (name, [PurePosixPath(p).name for p in dependencies])

    memo = {}
    visiting = set()

    def violations(key):
        if key in memo:
            return memo[key]
        if key in visiting:
            raise ValueError("cyclic Nix derivation graph")
        visiting.add(key)
        name, dependencies = graph[key]  # Missing dependencies fail closed.
        found = {name} if FORBIDDEN.search(name) else set()
        for dependency in dependencies:
            found.update(violations(dependency))
        visiting.remove(key)
        memo[key] = found
        return found

    skipped = {}
    for component, path in packages.items():
        found = violations(PurePosixPath(path).name)
        if found:
            skipped[component] = "Forbidden Java/Maven/Android dependency: " + ", ".join(sorted(found))
    return skipped


def homebrew_record(kind, name, document, tap, platform):
    """Bind API metadata to the immutable Ruby source used by Homebrew."""
    if not re.fullmatch(r"[a-z0-9][a-z0-9+_.@-]*", name):
        raise ValueError(f"unsupported Homebrew name: {name}")
    if document["token" if kind == "cask" else "name"] != name:
        raise ValueError(f"Homebrew identity mismatch: {name}")
    relative = PurePosixPath(document["ruby_source_path"])
    directory = "Casks" if kind == "cask" else "Formula"
    if relative.is_absolute() or ".." in relative.parts or not relative.parts or relative.parts[0] != directory or relative.name != name + ".rb":
        raise ValueError(f"invalid Homebrew source path: {name}")
    source = tap / relative
    if not source.resolve().is_relative_to(tap.resolve()):
        raise ValueError(f"Homebrew source escapes tap: {name}")
    if hashlib.sha256(source.read_bytes()).hexdigest() != document["ruby_source_checksum"]["sha256"]:
        raise ValueError(f"Homebrew source mismatch: {name}; retry after upstream metadata catches up")

    def merge(base, override):
        result = dict(base)
        for key, value in override.items():
            result[key] = merge(result.get(key, {}), value) if isinstance(value, dict) else value
        return result

    return merge(document, document.get("variations", {}).get(platform, {}))


def classify_homebrew(casks, load):
    """Check recursive declarations; only known app/link footprints are admitted."""
    records, memo, visiting = {}, {}, set()

    def visit(kind, name):
        key = kind, name
        if key in memo:
            return memo[key]
        if key in visiting:
            raise ValueError("cyclic Homebrew dependency graph")
        visiting.add(key)
        doc = records[key] = load(kind, name)
        forbidden = {name} if FORBIDDEN.search(name.replace("@", "-")) or name == "java" else set()
        edges = []

        def dependencies(dependency_kind, values):
            if not isinstance(values, list) or any(not isinstance(n, str) or not n for n in values):
                raise ValueError(f"invalid Homebrew dependency list: {name}")
            edges.extend((dependency_kind, n) for n in values)

        if kind == "cask":
            depends = doc["depends_on"]
            if not isinstance(depends, dict):
                raise ValueError(f"invalid Homebrew dependency record: {name}")
            if set(depends) - {"cask", "formula", "macos", "arch"}:
                raise ValueError(f"unknown Homebrew dependency kind: {name}")
            for dependency_kind in ("cask", "formula"):
                dependencies(dependency_kind, depends.get(dependency_kind, []))
        else:
            for field in ("dependencies", "build_dependencies"):
                dependencies("formula", doc[field])
            dependencies("formula", doc.get("recommended_dependencies", []))
            # Conservatively include macOS-provided dependencies' fallback
            # formulae, rather than relying on the current host's installations.
            if not isinstance(doc["uses_from_macos"], list) or not isinstance(doc["requirements"], list):
                raise ValueError(f"invalid Homebrew formula requirements: {name}")
            for dependency in doc["uses_from_macos"]:
                dependencies("formula", list(dependency) if isinstance(dependency, dict) else [dependency])
            for requirement in doc["requirements"]:
                if requirement["name"] == "java" or FORBIDDEN.search(requirement["name"]):
                    forbidden.add(requirement["name"])
        for dependency_kind, dependency in edges:
            if not isinstance(dependency, str):
                raise ValueError(f"invalid Homebrew dependency: {name}")
            forbidden.update(visit(dependency_kind, dependency)[0])
        visiting.remove(key)
        memo[key] = forbidden, edges
        return memo[key]

    result = {"skipped": {}, "artifacts": {}}
    for name, app in casks.items():
        forbidden, edges = visit("cask", name)
        if forbidden:
            result["skipped"][name] = "Forbidden Java/Maven/Android dependency: " + ", ".join(sorted(forbidden))
            continue
        # Current approved casks have no package dependencies. Do not silently
        # introduce a second cask/formula owner when upstream adds a new one.
        if edges:
            raise ValueError(f"unreviewed Homebrew dependency footprint: {name}")
        paths = {}
        for artifact in records["cask", name]["artifacts"]:
            kinds = set(artifact) - {"target"}
            if len(kinds) != 1:
                raise ValueError(f"invalid Homebrew artifact: {name}")
            kind = kinds.pop()
            if kind == "zap":  # Never invoked: cleanup/zap are disabled.
                continue
            if kind == "uninstall":
                if any(set(step) - {"quit", "launchctl", "login_item"} for step in artifact[kind]):
                    raise ValueError(f"unreviewed Homebrew uninstall effects: {name}")
                continue
            target = artifact.get("target", "").replace("$APPDIR", "/Applications").replace("$HOMEBREW_PREFIX", "/opt/homebrew")
            if ".." in PurePosixPath(target).parts or "\n" in target or "\t" in target:
                raise ValueError(f"invalid Homebrew artifact path: {name}")
            if target in paths or any(target in other for other in result["artifacts"].values()):
                raise ValueError(f"colliding Homebrew artifact: {target}")
            if kind == "app" and target == f"/Applications/{app}" and artifact[kind] == [app]:
                paths[target] = {"kind": "app"}
            elif kind in {"binary", "manpage", "bash_completion", "zsh_completion", "fish_completion"}:
                source = artifact[kind][0].replace("$APPDIR", "/Applications")
                if not target.startswith("/opt/homebrew/") or not source.startswith(f"/Applications/{app}/") or ".." in PurePosixPath(source).parts or "\n" in source or "\t" in source:
                    raise ValueError(f"unsupported Homebrew link: {name}")
                paths[target] = {"kind": "link", "source": source}
            else:
                raise ValueError(f"unreviewed Homebrew artifact {kind}: {name}")
        if f"/Applications/{app}" not in paths:
            raise ValueError(f"missing Homebrew app artifact: {name}")
        result["artifacts"][name] = paths
    return result


def resolve_homebrew(casks, core, cask_tap, os_version):
    names = {11: "big_sur", 12: "monterey", 13: "ventura", 14: "sonoma", 15: "sequoia", 26: "tahoe", 27: "golden_gate"}
    platform = "arm64_" + names[int(os_version.split(".")[0])]

    def load(kind, name):
        if not re.fullmatch(r"[a-z0-9][a-z0-9+_.@-]*", name):
            raise ValueError(f"unsupported Homebrew name: {name}")
        with urlopen(f"https://formulae.brew.sh/api/{kind}/{quote(name)}.json", timeout=30) as response:
            document = json.load(response)
        return homebrew_record(kind, name, document, cask_tap if kind == "cask" else core, platform)

    return classify_homebrew(casks, load) | {"osVersion": os_version, "core": str(core), "cask": str(cask_tap)}


if __name__ == "__main__":
    try:
        if sys.argv[1] == "--homebrew":
            with open(sys.argv[2]) as source:
                packages = json.load(source)
            result = resolve_homebrew(packages, Path(sys.argv[3]), Path(sys.argv[4]), sys.argv[5])
        else:
            with open(sys.argv[1]) as source:
                packages = json.load(source)
            with open(sys.argv[2]) as source:
                graph = json.load(source)
            result = classify(packages, graph)
        print(json.dumps(result, sort_keys=True))
    except (IndexError, KeyError, TypeError, ValueError, OSError, RecursionError) as error:
        raise SystemExit(f"Cannot establish dependency safety: {error}") from error
