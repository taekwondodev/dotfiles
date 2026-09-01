from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from typing import Any, Callable


REQUIRED_MODEL = "deepseek-v4-flash"
REQUIRED_PROVIDER = "opencode-go"
EXPECTED_MATRIX_SHA256 = "603b4c65e201c2ec821b4ca854b37dba87a1f4c10ad0c6e25390ffa4606e8aee"
REQUIRED_RESPONSE_KEYS = {
    "id",
    "verdict",
    "decisions",
    "read_only",
    "delegated",
    "summary",
}
DECISION_KEYS = {"id", "claim", "supported", "classification", "evidence"}


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


def policy_files(matrix: dict[str, Any]) -> list[str]:
    return sorted(
        {
            relative
            for scenario in matrix["scenarios"]
            for relative in scenario["policy_files"]
        }
    )


def policy_sha256(matrix: dict[str, Any], read: Callable[[str], str]) -> str:
    material = "".join(
        f"{relative}\0{read(relative)}\0" for relative in policy_files(matrix)
    ).encode()
    return hashlib.sha256(material).hexdigest()


def build_prompt(scenario: dict[str, Any], read: Callable[[str], str]) -> str:
    public_scenario = {
        key: value for key, value in scenario.items() if key != "expected"
    }
    policies = "\n".join(
        f'<policy path="{relative}">\n{read(relative)}\n</policy>'
        for relative in scenario["policy_files"]
    )
    return f"""You are a bounded {scenario['role']} subagent. Apply only the supplied role policies to the supplied task context. This is a read-only evaluation. Use no tools, make no changes, and do not delegate.

Evaluate every candidate claim. A candidate belongs in selected only when its claim sentence is true as written and the supplied evidence supports it under the role policy. Its classification labels that supported claim; it never corrects or reinterprets a false claim. Every unsupported, contradicted, or false-as-written candidate belongs in rejected. Do not invent claims outside the supplied candidates.

Return exactly one object inside <eval-json> and </eval-json>. The content between the tags must be valid JSON with no markdown fence and exactly this schema. The root object consists of the seven displayed keys. Put classifications only inside selected items:
{{
  "id": "scenario id",
  "verdict": "findings or pass",
  "decisions": [
    {{
      "id": "candidate id",
      "claim": "exact candidate claim text",
      "supported": true,
      "classification": "one classification option, or null when unsupported",
      "evidence": ["every supplied evidence anchor, or an empty list when unsupported"]
    }}
  ],
  "read_only": true,
  "delegated": false,
  "summary": "one concise role-specific conclusion"
}}

Every candidate id must appear exactly once in decisions. For every candidate, copy its claim text exactly. Set supported to true only when the claim is true as written; then use one supplied classification and every evidence_options anchor. When the claim is unsupported, contradicted, or false as written, set supported to false, classification to null, and evidence to an empty list. Use only exact candidate ids, classification options, and evidence anchors from the scenario. The summary is the final root field; close the object and then the eval-json tag. Set verdict to findings when any decision is supported, otherwise pass.

<scenario>
{json.dumps(public_scenario, indent=2)}
</scenario>

<policy-bundle>
{policies}
</policy-bundle>
"""


def parse_response(stdout: str) -> dict[str, Any]:
    matches = re.findall(
        r"<eval-json>\s*(\{.*?\})\s*</eval-json>", stdout, re.DOTALL
    )
    if len(matches) != 1:
        raise ValueError(f"expected one eval JSON object, found {len(matches)}")
    payload = json.loads(matches[0])
    if not isinstance(payload, dict):
        raise ValueError("eval payload must be an object")
    return payload


def run_hermes_scenario(
    prompt: str,
    run_budget: int,
    infrastructure_retries: int,
    model: str = REQUIRED_MODEL,
    provider: str = REQUIRED_PROVIDER,
) -> dict[str, Any]:
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
        "--model",
        model,
        "--provider",
        provider,
    ]
    errors: list[str] = []
    for attempt in range(1, infrastructure_retries + 2):
        try:
            result = subprocess.run(
                command,
                input=prompt,
                check=False,
                capture_output=True,
                text=True,
                timeout=run_budget + 30,
            )
        except subprocess.TimeoutExpired:
            errors.append(f"attempt {attempt}: timed out")
            continue
        if result.returncode != 0:
            errors.append(
                f"attempt {attempt}: Hermes exited {result.returncode}: "
                f"{result.stderr.strip()[-1000:]}"
            )
            continue
        try:
            observed = parse_response(result.stdout)
        except (ValueError, json.JSONDecodeError) as error:
            errors.append(f"attempt {attempt}: {error}")
            continue
        return {
            "attempts": attempt,
            "infrastructure_errors": errors,
            "observed": observed,
        }
    return {
        "attempts": infrastructure_retries + 1,
        "infrastructure_errors": errors,
        "observed": None,
    }


def compare_scenario(
    scenario: dict[str, Any], observed: dict[str, Any] | None
) -> list[str]:
    if observed is None:
        return ["no parseable response after infrastructure retries"]

    failures: list[str] = []
    actual_keys = set(observed)
    missing_response_keys = sorted(REQUIRED_RESPONSE_KEYS - actual_keys)
    if missing_response_keys:
        failures.append(f"response missing required keys {missing_response_keys}")

    if observed.get("id") != scenario["id"]:
        failures.append(
            f"id expected {scenario['id']!r}, got {observed.get('id')!r}"
        )
    if observed.get("verdict") != scenario["expected"]["verdict"]:
        failures.append(
            f"verdict expected {scenario['expected']['verdict']!r}, "
            f"got {observed.get('verdict')!r}"
        )
    if observed.get("read_only") is not True:
        failures.append("read_only must be true")
    if observed.get("delegated") is not False:
        failures.append("delegated must be false")
    summary = observed.get("summary")
    if not isinstance(summary, str) or not summary.strip():
        failures.append("summary must be a non-empty string")

    raw_decisions = observed.get("decisions")
    decisions_by_id: dict[str, dict[str, Any]] = {}
    if not isinstance(raw_decisions, list):
        failures.append("decisions must be a list")
        raw_decisions = []
    for index, decision in enumerate(raw_decisions):
        if not isinstance(decision, dict):
            failures.append(f"decision {index} must be an object")
            continue
        if set(decision) != DECISION_KEYS:
            failures.append(
                f"decision {index} keys expected {sorted(DECISION_KEYS)}, "
                f"got {sorted(decision)}"
            )
        identifier = decision.get("id")
        if not isinstance(identifier, str):
            failures.append(f"decision {index} id must be a string")
            continue
        if identifier in decisions_by_id:
            failures.append(f"decisions contains duplicate {identifier!r}")
            continue
        decisions_by_id[identifier] = decision

    candidate_by_id = {item["id"]: item for item in scenario["candidates"]}
    candidate_ids = set(candidate_by_id)
    decision_ids = set(decisions_by_id)
    unknown = sorted(decision_ids - candidate_ids)
    if unknown:
        failures.append(f"unknown candidate ids {unknown}")
    missing = sorted(candidate_ids - decision_ids)
    if missing:
        failures.append(f"unclassified candidate ids {missing}")

    expected_selected = scenario["expected"]["selected"]
    expected_selected_ids = set(expected_selected)
    expected_rejected = set(scenario["expected"]["rejected"])
    if expected_rejected != candidate_ids - expected_selected_ids:
        failures.append("matrix expected decisions do not partition the candidates")

    for identifier, decision in decisions_by_id.items():
        candidate = candidate_by_id.get(identifier)
        if candidate is None:
            continue
        claim = decision.get("claim")
        if claim != candidate["claim"]:
            failures.append(
                f"{identifier} claim expected {candidate['claim']!r}, got {claim!r}"
            )

        supported = decision.get("supported")
        if not isinstance(supported, bool):
            failures.append(f"{identifier} supported must be a boolean")
            continue
        expected_support = identifier in expected_selected_ids
        if supported is not expected_support:
            failures.append(
                f"{identifier} supported expected {expected_support}, got {supported}"
            )

        classification = decision.get("classification")
        evidence = decision.get("evidence")
        if supported:
            if classification not in candidate["classification_options"]:
                failures.append(
                    f"{identifier} classification {classification!r} is not an allowed option"
                )
            if not isinstance(evidence, list) or not all(
                isinstance(item, str) for item in evidence
            ):
                failures.append(f"{identifier} evidence must be a list of anchors")
            elif set(evidence) != set(candidate["evidence_options"]):
                failures.append(
                    f"{identifier} evidence expected {sorted(candidate['evidence_options'])}, "
                    f"got {sorted(evidence)}"
                )
        else:
            if classification is not None:
                failures.append(
                    f"{identifier} unsupported classification must be null"
                )
            if evidence != []:
                failures.append(f"{identifier} unsupported evidence must be empty")

        expected = expected_selected.get(identifier)
        if expected is not None and classification != expected["classification"]:
            failures.append(
                f"{identifier} classification expected {expected['classification']!r}, "
                f"got {classification!r}"
            )

    return failures


def evaluate_policy(
    matrix: dict[str, Any],
    read: Callable[[str], str],
    repetitions: int,
    workers: int,
    run_budget: int,
    infrastructure_retries: int,
) -> dict[str, Any]:
    jobs = [
        (scenario, repetition)
        for repetition in range(1, repetitions + 1)
        for scenario in matrix["scenarios"]
    ]
    records: dict[tuple[str, int], dict[str, Any]] = {}
    with ThreadPoolExecutor(max_workers=workers) as executor:
        futures = {
            executor.submit(
                run_hermes_scenario,
                build_prompt(scenario, read),
                run_budget,
                infrastructure_retries,
            ): (scenario, repetition)
            for scenario, repetition in jobs
        }
        for future in as_completed(futures):
            scenario, repetition = futures[future]
            records[(scenario["id"], repetition)] = future.result()

    failures: dict[str, list[str]] = {}
    runs: list[dict[str, Any]] = []
    for scenario, repetition in jobs:
        record = records[(scenario["id"], repetition)]
        semantic_failures = compare_scenario(scenario, record["observed"])
        run_id = f"{scenario['id']}#run-{repetition}"
        if semantic_failures:
            failures[run_id] = semantic_failures
        runs.append(
            {
                "scenario": scenario["id"],
                "role": scenario["role"],
                "repetition": repetition,
                **record,
                "failures": semantic_failures,
            }
        )
    return {"runs": runs, "failures": failures}


def evaluate_variants(
    variants: list[tuple[str, Callable[[str], str]]],
    matrix: dict[str, Any],
    repetitions: int,
    workers: int,
    run_budget: int,
    infrastructure_retries: int,
) -> dict[str, dict[str, Any]]:
    results: dict[str, dict[str, Any]] = {}
    decisions_by_policy: dict[str, tuple[str, dict[str, Any]]] = {}
    for variant, read in variants:
        digest = policy_sha256(matrix, read)
        existing = decisions_by_policy.get(digest)
        if existing is not None:
            source_variant, evaluation = existing
            results[variant] = {
                "policy_sha256": digest,
                "decision_source": "identical-policy-alias",
                "policy_alias_of": source_variant,
                **evaluation,
                "blocking_failures": evaluation["failures"],
            }
            continue
        evaluation = evaluate_policy(
            matrix,
            read,
            repetitions,
            workers,
            run_budget,
            infrastructure_retries,
        )
        decisions_by_policy[digest] = (variant, evaluation)
        results[variant] = {
            "policy_sha256": digest,
            "decision_source": "fresh-run",
            **evaluation,
            "blocking_failures": evaluation["failures"],
        }
    return results


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrix", type=Path)
    parser.add_argument("--baseline-ref", default="HEAD")
    parser.add_argument("--candidate-only", action="store_true")
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--workers", type=int, default=5)
    parser.add_argument("--run-budget", type=int, default=180)
    parser.add_argument("--infrastructure-retries", type=int, default=1)
    parser.add_argument("--model", default=REQUIRED_MODEL)
    parser.add_argument("--provider", default=REQUIRED_PROVIDER)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    if args.model != REQUIRED_MODEL or args.provider != REQUIRED_PROVIDER:
        raise RuntimeError(
            "the blocking subagent gate must run deepseek-v4-flash via opencode-go"
        )
    if args.repetitions < 1 or args.workers < 1 or args.infrastructure_retries < 0:
        raise RuntimeError("repetitions and workers must be positive; retries cannot be negative")

    script_path = Path(__file__).resolve()
    repo = next(parent for parent in script_path.parents if (parent / ".git").exists())
    skills_root = repo / "hermes/.hermes/skills"
    matrix_path = (
        args.matrix
        or script_path.parent.parent / "references/subagent-scenarios.json"
    )
    output_path = args.output or repo / ".hermes/evals/subagent-behavior.json"
    matrix = json.loads(matrix_path.read_text())
    matrix_digest = hashlib.sha256(matrix_path.read_bytes()).hexdigest()
    if matrix_digest != EXPECTED_MATRIX_SHA256:
        raise RuntimeError(
            f"matrix does not match the immutable contract "
            f"(expected sha256 {EXPECTED_MATRIX_SHA256}, got {matrix_digest}); "
            "update EXPECTED_MATRIX_SHA256 only with an intentional contract change"
        )
    if len(matrix["scenarios"]) != matrix["expected_scenario_count"]:
        raise RuntimeError("scenario count does not match expected_scenario_count")

    variants = [("candidate", current_reader(skills_root))]
    if not args.candidate_only:
        variants.insert(0, ("baseline", baseline_reader(repo, args.baseline_ref)))
    variant_results = evaluate_variants(
        variants,
        matrix,
        args.repetitions,
        args.workers,
        args.run_budget,
        args.infrastructure_retries,
    )

    report: dict[str, Any] = {
        "matrix": str(matrix_path.relative_to(repo)),
        "matrix_sha256": matrix_digest,
        "runner_sha256": hashlib.sha256(script_path.read_bytes()).hexdigest(),
        "baseline_ref": None if args.candidate_only else args.baseline_ref,
        "model": REQUIRED_MODEL,
        "provider": REQUIRED_PROVIDER,
        "repetitions": args.repetitions,
        "workers": args.workers,
        "infrastructure_retries": args.infrastructure_retries,
        "variants": variant_results,
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2) + "\n")

    for variant, _ in variants:
        result = variant_results[variant]
        print(
            f"{variant}\truns={len(result['runs'])}\t"
            f"failures={len(result['failures'])}\t"
            f"source={result['decision_source']}"
        )
        for run_id, messages in result["failures"].items():
            for message in messages:
                print(f"{variant}_failure\t{run_id}\t{message}")
    print(f"report\t{output_path}")

    return 1 if variant_results["candidate"]["blocking_failures"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
