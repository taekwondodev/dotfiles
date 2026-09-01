from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path
from typing import Any, Callable


POLICY_FILES = [
    "dev-cycle/SKILL.md",
    "grilling/SKILL.md",
    "architect/SKILL.md",
    "to-spec/SKILL.md",
    "to-tickets/SKILL.md",
    "implement/SKILL.md",
    "code-review/SKILL.md",
    "wayfinder/SKILL.md",
    "handoff/SKILL.md",
    "principle-prove-it-works/SKILL.md",
    "menu/SKILL.md",
]

PRIMARY_MODES = [
    "investigation",
    "bug_fix",
    "feature",
    "refactoring",
    "performance_issue",
    "hillclimb",
    "architecture",
    "large_work",
    "catalog",
]

# Immutable approved 16-scenario contract. The runner refuses to evaluate a
# candidate matrix whose SHA-256 differs, so the expected set of scenarios,
# capabilities, and checkpoints cannot be silently weakened by a future edit.
# Changing scenarios deliberately requires updating this hash in the same commit.
EXPECTED_MATRIX_SHA256 = "f4545ce35758071b93888bca0da8654be9cd81d09000d5d21ddfebb8de4dfb0f"

def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=repo,
        check=False,
        capture_output=True,
        text=True,
    )


def current_reader(skills_root: Path) -> Callable[[str], str]:
    def read(relative: str) -> str:
        return (skills_root / relative).read_text()

    return read


def baseline_reader(repo: Path, baseline_ref: str) -> Callable[[str], str]:
    def read(relative: str) -> str:
        result = git(repo, "show", f"{baseline_ref}:hermes/.hermes/skills/{relative}")
        if result.returncode != 0:
            raise RuntimeError(f"baseline missing {relative}: {result.stderr.strip()}")
        return result.stdout

    return read


def policy_sha256(read: Callable[[str], str]) -> str:
    material = "".join(
        f"{relative}\0{read(relative)}\0" for relative in POLICY_FILES
    ).encode()
    return hashlib.sha256(material).hexdigest()


def build_prompt(matrix: dict[str, Any], read: Callable[[str], str]) -> str:
    scenarios = [{"id": item["id"], "prompt": item["prompt"]} for item in matrix["scenarios"]]
    policies = []
    for relative in POLICY_FILES:
        policies.append(f"<policy path=\"{relative}\">\n{read(relative)}\n</policy>")

    return f"""You are the workflow router. Apply the supplied policy bundle to each user request and emit the route you would follow. This is a routing exercise: do not perform the requested repository changes or call tools.

Return exactly one object per scenario inside <eval-json> and </eval-json>. The content between those tags must be valid JSON with no markdown fences.

Each object must have this schema:
{{
  "id": "scenario id",
  "primary_mode": "one allowed primary mode",
  "capabilities": ["canonical skill names the workflow activates"],
  "principles": ["exact principle-* skill names whose trigger fires"],
  "checkpoint": "one allowed checkpoint",
  "questions_before_evidence": ["questions asked before gathering available evidence"],
  "testing_methods": ["named testing methodologies the route requires"],
  "architecture_styles": ["architecture styles the route requires"],
  "review_axes": ["Standards", "Spec", "Adversarial"],
  "verification_steps": [
    {{"artifact": "real artifact being checked", "observation": "concrete result required"}}
  ]
}}

Allowed primary modes: {json.dumps(PRIMARY_MODES)}

Allowed checkpoints and meanings:
- none: no human decision is needed before the routed work can proceed.
- human_owned_contract: a public contract decision requires human ownership.
- product_scope: product behavior or scope requires the governed checkpoint.
- product_scope_boundary: product or scope plus a boundary decision requires the governed checkpoint.
- conditional_contract_change: proceed only while behavior and contracts remain fixed; promote if they change.
- target_stop_predicate: the human owns the metric target and stopping condition.
- explicit_only: standalone architecture proceeds unless the user explicitly requests a checkpoint.
- hitl_decisions: the map contains human-owned decision tickets while factual research remains autonomous.
- user_choice: catalog output is neutral and the user chooses what to invoke.

Use canonical skill names for capabilities. Capabilities describe the complete eventual route, including phases after a required checkpoint and every skill that a routed phase says it must load as a dependency or standard; do not truncate the route at the checkpoint. Assume the user approves the proposed direction without changing the requirements, and use the checkpoint field to record where the route pauses. Include only principles that concretely change routing, ownership, implementation, or verification for that scenario. A bug that requires a public API change is promoted to feature. `questions_before_evidence` contains only questions asked before repository inspection, tests, profiling, or other available evidence; do not include later human-owned decision questions. Name a testing methodology or architecture style only when the route actually requires it. For review_axes, return all three names when the complete route activates code-review, even when a checkpoint occurs first; otherwise return an empty array. Every route must name at least one verification object whose artifact is the real thing being checked and whose observation is the concrete result required before completion.

<scenarios>
{json.dumps(scenarios, indent=2)}
</scenarios>

<policy-bundle>
{chr(10).join(policies)}
</policy-bundle>
"""


def run_hermes(prompt: str, run_budget: int, model: str | None, provider: str | None) -> list[dict[str, Any]]:
    command = [
        "hermes",
        "chat",
        "--query-file",
        "-",
        "-Q",
        "--ignore-rules",
        "--source",
        "tool",
        "--max-turns",
        "1",
        "--run-budget",
        str(run_budget),
    ]
    if model:
        command.extend(["--model", model])
    if provider:
        command.extend(["--provider", provider])

    result = subprocess.run(
        command,
        input=prompt,
        check=False,
        capture_output=True,
        text=True,
        timeout=run_budget + 30,
    )
    if result.returncode != 0:
        raise RuntimeError(f"Hermes exited {result.returncode}: {result.stderr.strip()}")

    match = re.search(r"<eval-json>\s*(\[.*\])\s*</eval-json>", result.stdout, re.DOTALL)
    if not match:
        raise RuntimeError(f"Hermes response has no eval JSON: {result.stdout[-2000:]}")
    payload = json.loads(match.group(1))
    if not isinstance(payload, list):
        raise RuntimeError("Hermes eval payload must be a list")
    return payload


def compare(
    matrix: dict[str, Any],
    observed: list[dict[str, Any]],
    known_skills: set[str],
) -> dict[str, list[str]]:
    expected_by_id = {item["id"]: item for item in matrix["scenarios"]}
    observed_by_id: dict[str, dict[str, Any]] = {}
    payload_failures = []
    for index, item in enumerate(observed):
        if not isinstance(item, dict):
            payload_failures.append(f"scenario result at index {index} must be an object")
            continue
        identifier = item.get("id")
        if not isinstance(identifier, str):
            payload_failures.append(
                f"scenario id at index {index} must be a string, got {identifier!r}"
            )
            continue
        if identifier in observed_by_id:
            payload_failures.append(f"duplicate scenario id {identifier!r}")
            continue
        observed_by_id[identifier] = item
    failures: dict[str, list[str]] = {}

    if payload_failures:
        failures["payload"] = payload_failures

    for identifier, expected in expected_by_id.items():
        actual = observed_by_id.get(identifier)
        if actual is None:
            failures[identifier] = ["missing scenario result"]
            continue

        scenario_failures = []
        actual_identifier = actual.get("id")
        if str(actual_identifier) != identifier:
            scenario_failures.append(
                f"id expected {identifier!r}, got {actual_identifier!r}"
            )
        actual_primary_mode = actual.get("primary_mode")
        if not isinstance(actual_primary_mode, str):
            scenario_failures.append(
                f"primary_mode must be a string, got {actual_primary_mode!r}"
            )
        elif actual_primary_mode != expected["primary_mode"]:
            scenario_failures.append(
                f"primary_mode expected {expected['primary_mode']!r}, got {actual_primary_mode!r}"
            )
        expected_checkpoint = expected["checkpoint"]
        allowed_checkpoints = (
            set(expected_checkpoint) if isinstance(expected_checkpoint, list) else {expected_checkpoint}
        )
        actual_checkpoint = actual.get("checkpoint")
        if not isinstance(actual_checkpoint, str):
            scenario_failures.append(
                f"checkpoint must be a string, got {actual_checkpoint!r}"
            )
        elif actual_checkpoint not in allowed_checkpoints:
            scenario_failures.append(
                f"checkpoint expected one of {sorted(allowed_checkpoints)!r}, got {actual_checkpoint!r}"
            )

        raw_capabilities = actual.get("capabilities")
        if not isinstance(raw_capabilities, list) or not all(
            isinstance(item, str) for item in raw_capabilities
        ):
            scenario_failures.append("capabilities must be a list of skill names")
            raw_capabilities = []
        actual_capabilities = set(raw_capabilities)
        if len(raw_capabilities) != len(actual_capabilities):
            scenario_failures.append("capabilities contain duplicates")
        scenario_known_skills = known_skills | set(expected.get("project_skills", []))
        unknown_capabilities = sorted(actual_capabilities - scenario_known_skills)
        if unknown_capabilities:
            scenario_failures.append(f"unknown capabilities {unknown_capabilities}")
        missing_capabilities = sorted(set(expected["capabilities"]) - actual_capabilities)
        if missing_capabilities:
            scenario_failures.append(f"missing capabilities {missing_capabilities}")
        optional_capabilities = set(matrix.get("optional_capabilities", {}).get(identifier, []))
        optional_capabilities.update(expected.get("optional_capabilities", []))
        unexpected_capabilities = sorted(
            actual_capabilities - set(expected["capabilities"]) - optional_capabilities
        )
        if unexpected_capabilities:
            scenario_failures.append(f"unexpected capabilities {unexpected_capabilities}")
        forbidden_capabilities = set(matrix.get("forbidden_capabilities", [])) | set(
            expected.get("forbidden_capabilities", [])
        )
        activated_forbidden = sorted(actual_capabilities & forbidden_capabilities)
        if activated_forbidden:
            scenario_failures.append(f"forbidden capabilities {activated_forbidden}")

        raw_principles = actual.get("principles")
        if not isinstance(raw_principles, list) or not all(
            isinstance(item, str) for item in raw_principles
        ):
            scenario_failures.append("principles must be a list of skill names")
            raw_principles = []
        actual_principles = set(raw_principles)
        if len(raw_principles) != len(actual_principles):
            scenario_failures.append("principles contain duplicates")
        unknown_principles = sorted(actual_principles - known_skills)
        if unknown_principles:
            scenario_failures.append(f"unknown principles {unknown_principles}")
        expected_principles = set(expected["principles"])
        optional_principles = set(matrix.get("optional_principles", {}).get(identifier, []))
        optional_principles.update(expected.get("optional_principles", []))
        unexpected_principles = sorted(
            actual_principles - expected_principles - optional_principles
        )
        if unexpected_principles:
            scenario_failures.append(f"unexpected principles {unexpected_principles}")
        non_principle_skills = sorted(
            principle for principle in actual_principles if not principle.startswith("principle-")
        )
        if non_principle_skills:
            scenario_failures.append(f"non-principle skills in principles {non_principle_skills}")
        if expected_principles and not (expected_principles & actual_principles):
            scenario_failures.append(
                f"none of the applicable principles were named: {sorted(expected_principles)}"
            )

        questions = actual.get("questions_before_evidence")
        if not isinstance(questions, list) or not all(isinstance(item, str) for item in questions):
            scenario_failures.append("questions_before_evidence must be a list of strings")
        elif questions:
            scenario_failures.append(f"asks questions before available evidence {questions}")

        testing_methods = actual.get("testing_methods")
        if not isinstance(testing_methods, list) or not all(
            isinstance(item, str) for item in testing_methods
        ):
            scenario_failures.append("testing_methods must be a list of strings")
        elif any(
            "tdd" in item.lower()
            or "testdrivendevelopment" in re.sub(r"[^a-z]", "", item.lower())
            for item in testing_methods
        ):
            scenario_failures.append(f"requires accidental TDD {testing_methods}")

        architecture_styles = actual.get("architecture_styles")
        if not isinstance(architecture_styles, list) or not all(
            isinstance(item, str) for item in architecture_styles
        ):
            scenario_failures.append("architecture_styles must be a list of strings")
        elif any(
            "hexagonal" in item.lower()
            or "portsandadapters" in re.sub(r"[^a-z]", "", item.lower())
            for item in architecture_styles
        ):
            scenario_failures.append(f"forces hexagonal architecture {architecture_styles}")

        verification_steps = actual.get("verification_steps")
        if not isinstance(verification_steps, list) or not verification_steps or not all(
            isinstance(item, dict)
            and isinstance(item.get("artifact"), str)
            and len(item["artifact"].strip()) >= 3
            and isinstance(item.get("observation"), str)
            and len(item["observation"].strip()) >= 3
            for item in verification_steps
        ):
            scenario_failures.append(
                "verification_steps must contain artifact and observation objects"
            )

        expected_axes = (
            {"Standards", "Spec", "Adversarial"}
            if "code-review" in actual_capabilities
            else set()
        )
        raw_axes = actual.get("review_axes")
        if not isinstance(raw_axes, list) or not all(
            isinstance(item, str) for item in raw_axes
        ):
            scenario_failures.append("review_axes must be a list of strings")
            actual_axes: set[str] = set()
        else:
            actual_axes = set(raw_axes)
        if actual_axes != expected_axes:
            scenario_failures.append(
                f"review_axes expected {sorted(expected_axes)}, got {sorted(actual_axes)}"
            )

        if scenario_failures:
            failures[identifier] = scenario_failures

    unexpected = sorted(str(identifier) for identifier in observed_by_id if identifier not in expected_by_id)
    if unexpected:
        failures["payload"] = [*failures.get("payload", []), f"unexpected scenario ids {unexpected}"]
    return failures


def evaluate_variants(
    variants: list[tuple[str, Callable[[str], str]]],
    matrix: dict[str, Any],
    known_skills: set[str],
    run_budget: int,
    model: str | None,
    provider: str | None,
) -> dict[str, dict[str, Any]]:
    results: dict[str, dict[str, Any]] = {}
    decisions_by_policy: dict[str, tuple[str, list[dict[str, Any]], dict[str, list[str]]]] = {}

    for variant, read in variants:
        digest = policy_sha256(read)
        existing = decisions_by_policy.get(digest)
        if existing is not None:
            source_variant, observed, failures = existing
            results[variant] = {
                "policy_sha256": digest,
                "decision_source": "identical-policy-alias",
                "policy_alias_of": source_variant,
                "observed": observed,
                "failures": failures,
                "blocking_failures": {},
            }
            continue

        observed = run_hermes(build_prompt(matrix, read), run_budget, model, provider)
        failures = compare(matrix, observed, known_skills)
        decisions_by_policy[digest] = (variant, observed, failures)
        results[variant] = {
            "policy_sha256": digest,
            "decision_source": "fresh-run",
            "observed": observed,
            "failures": failures,
            "blocking_failures": failures,
        }

    return results


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrix", type=Path)
    parser.add_argument("--baseline-ref", default="HEAD")
    parser.add_argument("--candidate-only", action="store_true")
    parser.add_argument("--model")
    parser.add_argument("--provider")
    parser.add_argument("--run-budget", type=int, default=480)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    script_path = Path(__file__).resolve()
    repo = next(parent for parent in script_path.parents if (parent / ".git").exists())
    skills_root = repo / "hermes/.hermes/skills"
    matrix_path = args.matrix or script_path.parent.parent / "references/dev-cycle-scenarios.json"
    output_path = args.output or repo / ".hermes/evals/dev-cycle-behavior.json"
    matrix = json.loads(matrix_path.read_text())
    matrix_digest = hashlib.sha256(matrix_path.read_bytes()).hexdigest()
    if matrix_digest != EXPECTED_MATRIX_SHA256:
        raise RuntimeError(
            f"matrix does not match the immutable contract "
            f"(expected sha256 {EXPECTED_MATRIX_SHA256}, got {matrix_digest}); "
            "if the scenario contract changed intentionally, update "
            "EXPECTED_MATRIX_SHA256 in the same commit"
        )

    variants = [("candidate", current_reader(skills_root))]
    if not args.candidate_only:
        variants.insert(0, ("baseline", baseline_reader(repo, args.baseline_ref)))

    known_skills = {path.parent.name for path in skills_root.glob("*/SKILL.md")}
    variant_results = evaluate_variants(
        variants,
        matrix,
        known_skills,
        args.run_budget,
        args.model,
        args.provider,
    )

    report: dict[str, Any] = {
        "matrix": str(matrix_path.relative_to(repo)),
        "matrix_sha256": hashlib.sha256(matrix_path.read_bytes()).hexdigest(),
        "runner_sha256": hashlib.sha256(script_path.read_bytes()).hexdigest(),
        "baseline_ref": None if args.candidate_only else args.baseline_ref,
        "model": args.model or "config-default",
        "provider": args.provider or "config-default",
        "candidate_source": variant_results["candidate"]["decision_source"],
        "variants": variant_results,
    }

    for variant, _ in variants:
        result = variant_results[variant]
        observed = result["observed"]
        failures = result["failures"]
        print(f"{variant}\tscenarios={len(observed)}\tfailures={len(failures)}")
        print(f"{variant}_decision_source\t{result['decision_source']}")
        if "policy_alias_of" in result:
            print(f"{variant}_policy_alias_of\t{result['policy_alias_of']}")
        for identifier, messages in failures.items():
            for message in messages:
                failure_kind = (
                    f"{variant}_shared_failure"
                    if result["decision_source"] == "identical-policy-alias"
                    else f"{variant}_failure"
                )
                print(f"{failure_kind}\t{identifier}\t{message}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2) + "\n")
    print(f"report\t{output_path}")

    candidate_failures = report["variants"]["candidate"]["blocking_failures"]
    return 1 if candidate_failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
