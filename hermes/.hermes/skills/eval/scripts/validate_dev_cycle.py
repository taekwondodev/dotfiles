from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path
from typing import Any, Callable


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo,
        check=False,
        capture_output=True,
        text=True,
    )


def current_reader(skills_root: Path) -> Callable[[str], str | None]:
    def read(relative: str) -> str | None:
        path = skills_root / relative
        return path.read_text() if path.is_file() else None

    return read


def baseline_reader(repo: Path, baseline_ref: str) -> Callable[[str], str | None]:
    def read(relative: str) -> str | None:
        result = git(repo, "show", f"{baseline_ref}:hermes/.hermes/skills/{relative}")
        return result.stdout if result.returncode == 0 else None

    return read


def evaluate_text_check(check: dict[str, Any], read: Callable[[str], str | None]) -> list[str]:
    relative = str(check["file"])
    content = read(relative)
    if content is None:
        return [f"missing {relative}"]

    failures = []
    for needle in check.get("contains", []):
        if str(needle) not in content:
            failures.append(f"{relative} missing {needle!r}")
    for needle in check.get("not_contains", []):
        if str(needle) in content:
            failures.append(f"{relative} contains forbidden {needle!r}")
    return failures


def skill_files_current(skills_root: Path, pattern: str) -> list[str]:
    return [str(path.relative_to(skills_root)) for path in skills_root.glob(pattern) if path.is_file()]


def skill_files_baseline(repo: Path, baseline_ref: str, pattern: str) -> list[str]:
    result = git(repo, "ls-tree", "-r", "--name-only", baseline_ref, "hermes/.hermes/skills")
    if result.returncode != 0:
        return []
    prefix = "hermes/.hermes/skills/"
    candidates = [line.removeprefix(prefix) for line in result.stdout.splitlines() if line.startswith(prefix)]
    return [relative for relative in candidates if Path(relative).match(pattern)]


def evaluate_global(
    check: dict[str, Any],
    read: Callable[[str], str | None],
    list_files: Callable[[str], list[str]],
) -> list[str]:
    if check.get("type") == "references_resolve":
        failures = []
        reference_pattern = re.compile(r"references/[A-Za-z0-9._/-]+\.md")
        for relative in list_files("*/SKILL.md"):
            content = read(relative)
            if content is None:
                failures.append(f"missing {relative}")
                continue
            skill_dir = Path(relative).parent
            for reference in sorted(set(reference_pattern.findall(content))):
                target = str(skill_dir / reference)
                if read(target) is None:
                    failures.append(f"{relative} points to missing {target}")
        return failures

    if "glob" in check:
        failures = []
        for relative in list_files(str(check["glob"])):
            content = read(relative)
            if content is None:
                failures.append(f"missing {relative}")
                continue
            for needle in check.get("not_contains", []):
                if str(needle) in content:
                    failures.append(f"{relative} contains forbidden {needle!r}")
            for needle in check.get("contains", []):
                if str(needle) not in content:
                    failures.append(f"{relative} missing {needle!r}")
        return failures

    failures = []
    for text_check in check.get("checks", []):
        failures.extend(evaluate_text_check(text_check, read))
    return failures


def evaluate_scenario(
    scenario: dict[str, Any],
    read: Callable[[str], str | None],
) -> list[str]:
    failures = []
    for name in [*scenario.get("capabilities", []), *scenario.get("principles", [])]:
        if read(f"{name}/SKILL.md") is None:
            failures.append(f"missing skill {name}")
    for check in scenario.get("checks", []):
        failures.extend(evaluate_text_check(check, read))
    return failures


def status(failures: list[str]) -> str:
    return "PASS" if not failures else "FAIL"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrix", type=Path)
    parser.add_argument("--baseline-ref", default="HEAD")
    parser.add_argument("--candidate-only", action="store_true")
    args = parser.parse_args()

    script_path = Path(__file__).resolve()
    repo = next(parent for parent in script_path.parents if (parent / ".git").exists())
    skills_root = repo / "hermes/.hermes/skills"
    matrix_path = args.matrix or script_path.parent.parent / "references/dev-cycle-scenarios.json"
    matrix = json.loads(matrix_path.read_text())
    scenarios = matrix["scenarios"]

    if len(scenarios) != matrix["expected_scenario_count"]:
        raise SystemExit("scenario count does not match expected_scenario_count")
    ids = [scenario["id"] for scenario in scenarios]
    if len(ids) != len(set(ids)):
        raise SystemExit("scenario ids must be unique")

    candidate_read = current_reader(skills_root)
    candidate_list = lambda pattern: skill_files_current(skills_root, pattern)
    baseline_read = baseline_reader(repo, args.baseline_ref)
    baseline_list = lambda pattern: skill_files_baseline(repo, args.baseline_ref, pattern)

    candidate_failures: dict[str, list[str]] = {}
    baseline_failures: dict[str, list[str]] = {}

    print("kind\tid\tbaseline\tcandidate")
    for scenario in scenarios:
        identifier = str(scenario["id"])
        candidate = evaluate_scenario(scenario, candidate_read)
        baseline = [] if args.candidate_only else evaluate_scenario(scenario, baseline_read)
        candidate_failures[f"scenario:{identifier}"] = candidate
        baseline_failures[f"scenario:{identifier}"] = baseline
        baseline_state = "SKIP" if args.candidate_only else status(baseline)
        print(f"scenario\t{identifier}\t{baseline_state}\t{status(candidate)}")

    for check in matrix["global_checks"]:
        identifier = str(check["id"])
        candidate = evaluate_global(check, candidate_read, candidate_list)
        baseline = [] if args.candidate_only else evaluate_global(check, baseline_read, baseline_list)
        candidate_failures[f"global:{identifier}"] = candidate
        baseline_failures[f"global:{identifier}"] = baseline
        baseline_state = "SKIP" if args.candidate_only else status(baseline)
        print(f"global\t{identifier}\t{baseline_state}\t{status(candidate)}")

    failed_candidate = {key: value for key, value in candidate_failures.items() if value}
    failed_baseline = {key: value for key, value in baseline_failures.items() if value}
    improved = sum(1 for key in failed_baseline if key not in failed_candidate)
    regressed = sum(1 for key in failed_candidate if key not in failed_baseline)

    print(
        f"summary\tscenarios={len(scenarios)}\tbaseline_failures={len(failed_baseline)}\t"
        f"candidate_failures={len(failed_candidate)}\timproved={improved}\tregressed={regressed}"
    )

    for key, failures in failed_candidate.items():
        for failure in failures:
            print(f"candidate_failure\t{key}\t{failure}")

    return 1 if failed_candidate else 0


if __name__ == "__main__":
    raise SystemExit(main())
