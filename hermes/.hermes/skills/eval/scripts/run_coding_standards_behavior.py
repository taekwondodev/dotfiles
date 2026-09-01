from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any, Callable

from run_dev_cycle_behavior import baseline_reader, current_reader, run_hermes


POLICY_FILE = "coding-standards/SKILL.md"
EXPECTED_MATRIX_SHA256 = "912e3872671b0b2a9adf2a1bbe4e1ce0e77d34a491f4920a84f5d6330869d6a5"
RESULT_FIELDS = {
    "validate_intrinsic_at_entry",
    "intrinsic_invariants_owned_by_types",
    "contextual_rules_owned_by_stateful_decider",
    "repeat_internal_validation",
    "recompute_established_facts",
    "decompose_by_domain_responsibility",
    "extract_only_to_satisfy_metric",
    "required_architecture_styles",
}


def policy_sha256(read: Callable[[str], str]) -> str:
    content = read(POLICY_FILE)
    return hashlib.sha256(f"{POLICY_FILE}\0{content}\0".encode()).hexdigest()


def build_prompt(matrix: dict[str, Any], read: Callable[[str], str]) -> str:
    scenarios = [
        {"id": scenario["id"], "prompt": scenario["prompt"]}
        for scenario in matrix["scenarios"]
    ]
    return f'''Apply the supplied coding standards to each scenario and state the concrete implementation behavior. This is a behavior decision exercise: do not modify files or call tools.

Return exactly one object per scenario inside <eval-json> and </eval-json>. The content between those tags must be a JSON array with no markdown fences.

Each object must have exactly this schema:
{{
  "id": "scenario id",
  "actions": ["concrete implementation action"],
  "validate_intrinsic_at_entry": true | false | null,
  "intrinsic_invariants_owned_by_types": true | false | null,
  "contextual_rules_owned_by_stateful_decider": true | false | null,
  "repeat_internal_validation": true | false | null,
  "recompute_established_facts": true | false | null,
  "decompose_by_domain_responsibility": true | false | null,
  "extract_only_to_satisfy_metric": true | false | null,
  "required_architecture_styles": ["style explicitly required by the decision"]
}}

Use null only when a field is genuinely not applicable to the scenario. `contextual_rules_owned_by_stateful_decider` is true when a rule requiring stored or mutable context remains with the operation that owns that state or decision rather than raw-input parsing. `required_architecture_styles` lists only mandatory named styles, not local types or functions.

<scenarios>
{json.dumps(scenarios, indent=2)}
</scenarios>

<policy path="{POLICY_FILE}">
{read(POLICY_FILE)}
</policy>
'''


def compare(matrix: dict[str, Any], observed: list[dict[str, Any]]) -> dict[str, list[str]]:
    expected_by_id = {scenario["id"]: scenario for scenario in matrix["scenarios"]}
    observed_by_id: dict[str, dict[str, Any]] = {}
    failures: dict[str, list[str]] = {}
    payload_failures = []

    for index, item in enumerate(observed):
        if not isinstance(item, dict):
            payload_failures.append(f"scenario result at index {index} must be an object")
            continue
        identifier = item.get("id")
        if not isinstance(identifier, str):
            payload_failures.append(f"scenario id at index {index} must be a string")
            continue
        if identifier in observed_by_id:
            payload_failures.append(f"duplicate scenario id {identifier!r}")
            continue
        observed_by_id[identifier] = item

    if payload_failures:
        failures["payload"] = payload_failures

    required_keys = {"id", "actions", *RESULT_FIELDS}
    for identifier, scenario in expected_by_id.items():
        actual = observed_by_id.get(identifier)
        if actual is None:
            failures[identifier] = ["missing scenario result"]
            continue

        scenario_failures = []
        if set(actual) != required_keys:
            scenario_failures.append(
                f"fields expected {sorted(required_keys)}, got {sorted(actual)}"
            )
        actions = actual.get("actions")
        if not isinstance(actions, list) or not actions or not all(
            isinstance(action, str) and action.strip() for action in actions
        ):
            scenario_failures.append("actions must be a non-empty list of strings")

        for field in RESULT_FIELDS:
            actual_value = actual.get(field)
            if field == "required_architecture_styles":
                if not isinstance(actual_value, list) or not all(
                    isinstance(style, str) for style in actual_value
                ):
                    scenario_failures.append(
                        "required_architecture_styles must be a list of strings"
                    )
            elif actual_value is not None and not isinstance(actual_value, bool):
                scenario_failures.append(f"{field} must be boolean or null")

        for field, expected in scenario["expect"].items():
            actual_value = actual.get(field)
            if actual_value != expected:
                scenario_failures.append(
                    f"{field} expected {expected!r}, got {actual_value!r}"
                )

        if scenario_failures:
            failures[identifier] = scenario_failures

    unexpected = sorted(set(observed_by_id) - set(expected_by_id))
    if unexpected:
        failures["payload"] = [
            *failures.get("payload", []),
            f"unexpected scenario ids {unexpected}",
        ]
    return failures


def evaluate_variants(
    variants: list[tuple[str, Callable[[str], str]]],
    matrix: dict[str, Any],
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
        failures = compare(matrix, observed)
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
    parser.add_argument("--run-budget", type=int, default=360)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    script_path = Path(__file__).resolve()
    repo = next(parent for parent in script_path.parents if (parent / ".git").exists())
    skills_root = repo / "hermes/.hermes/skills"
    matrix_path = (
        args.matrix
        or script_path.parent.parent / "references/coding-standards-scenarios.json"
    )
    output_path = (
        args.output or repo / ".hermes/evals/coding-standards-behavior.json"
    )
    matrix = json.loads(matrix_path.read_text())
    matrix_digest = hashlib.sha256(matrix_path.read_bytes()).hexdigest()
    if matrix_digest != EXPECTED_MATRIX_SHA256:
        raise RuntimeError(
            "matrix does not match the immutable contract "
            f"(expected sha256 {EXPECTED_MATRIX_SHA256}, got {matrix_digest})"
        )
    if len(matrix["scenarios"]) != matrix["expected_scenario_count"]:
        raise RuntimeError("scenario count does not match expected_scenario_count")

    variants = [("candidate", current_reader(skills_root))]
    if not args.candidate_only:
        variants.insert(0, ("baseline", baseline_reader(repo, args.baseline_ref)))
    variant_results = evaluate_variants(
        variants,
        matrix,
        args.run_budget,
        args.model,
        args.provider,
    )

    report = {
        "matrix": str(matrix_path.relative_to(repo)),
        "matrix_sha256": matrix_digest,
        "runner_sha256": hashlib.sha256(script_path.read_bytes()).hexdigest(),
        "baseline_ref": None if args.candidate_only else args.baseline_ref,
        "model": args.model or "config-default",
        "provider": args.provider or "config-default",
        "candidate_source": variant_results["candidate"]["decision_source"],
        "variants": variant_results,
    }

    for variant, _ in variants:
        result = variant_results[variant]
        failures = result["failures"]
        print(
            f"{variant}\tscenarios={len(result['observed'])}\t"
            f"failures={len(failures)}"
        )
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
    return 1 if variant_results["candidate"]["blocking_failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
