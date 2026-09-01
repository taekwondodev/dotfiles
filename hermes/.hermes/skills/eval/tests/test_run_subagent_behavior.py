from __future__ import annotations

import importlib.util
import json
import subprocess
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).parents[1] / "scripts" / "run_subagent_behavior.py"
SPEC = importlib.util.spec_from_file_location("run_subagent_behavior", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


def scenario() -> dict[str, object]:
    return {
        "id": "bounded",
        "role": "Test reviewer",
        "policy_files": ["policy/SKILL.md"],
        "task_context": "Evidence anchor: src/item.py:4",
        "candidates": [
            {
                "id": "T1",
                "claim": "The evidence supports this claim.",
                "classification_options": ["hard_violation", "judgement_call"],
                "evidence_options": ["src/item.py:4"],
            },
            {
                "id": "T2",
                "claim": "This is a distractor.",
                "classification_options": ["hard_violation", "judgement_call"],
                "evidence_options": ["src/item.py:9"],
            },
        ],
        "expected": {
            "verdict": "findings",
            "selected": {
                "T1": {
                    "classification": "hard_violation",
                    "evidence": ["src/item.py:4"],
                }
            },
            "rejected": ["T2"],
        },
    }


def passing_observed() -> dict[str, object]:
    return {
        "id": "bounded",
        "verdict": "findings",
        "decisions": [
            {
                "id": "T1",
                "claim": "The evidence supports this claim.",
                "supported": True,
                "classification": "hard_violation",
                "evidence": ["src/item.py:4"],
            },
            {
                "id": "T2",
                "claim": "This is a distractor.",
                "supported": False,
                "classification": None,
                "evidence": [],
            },
        ],
        "read_only": True,
        "delegated": False,
        "summary": "One supported finding.",
    }


class SubagentBehaviorRunnerTests(unittest.TestCase):
    def test_prompt_does_not_disclose_expected_decision(self) -> None:
        prompt = RUNNER.build_prompt(scenario(), lambda relative: f"policy:{relative}")

        self.assertNotIn('"expected"', prompt)
        self.assertNotIn('"classification": "hard_violation"', prompt)
        self.assertIn('"classification_options"', prompt)
        self.assertIn("bounded Test reviewer subagent", prompt)

    def test_compare_accepts_exact_semantic_result(self) -> None:
        self.assertEqual(
            RUNNER.compare_scenario(scenario(), passing_observed()),
            [],
        )

    def test_extra_root_metadata_does_not_change_semantic_result(self) -> None:
        observed = passing_observed()
        observed["finish_reason"] = "end_turn"

        self.assertEqual(RUNNER.compare_scenario(scenario(), observed), [])

    def test_missing_required_root_key_is_a_failure(self) -> None:
        observed = passing_observed()
        del observed["summary"]

        self.assertIn(
            "response missing required keys ['summary']",
            RUNNER.compare_scenario(scenario(), observed),
        )

    def test_compare_rejects_distractor_and_wrong_evidence(self) -> None:
        observed = passing_observed()
        observed["decisions"] = [
            {
                "id": "T1",
                "claim": "The evidence supports this claim.",
                "supported": False,
                "classification": None,
                "evidence": [],
            },
            {
                "id": "T2",
                "claim": "This is a distractor.",
                "supported": True,
                "classification": "invented_classification",
                "evidence": ["src/item.py:999"],
            },
        ]

        failures = RUNNER.compare_scenario(scenario(), observed)

        self.assertIn("T1 supported expected True, got False", failures)
        self.assertIn("T2 supported expected False, got True", failures)
        self.assertIn(
            "T2 classification 'invented_classification' is not an allowed option",
            failures,
        )
        self.assertIn("T2 evidence expected ['src/item.py:9'], got ['src/item.py:999']", failures)

    def test_shared_policy_failure_remains_blocking(self) -> None:
        matrix = {"scenarios": [scenario()]}
        readers = [
            ("baseline", lambda relative: f"same:{relative}"),
            ("candidate", lambda relative: f"same:{relative}"),
        ]
        evaluation = {
            "runs": [],
            "failures": {"bounded#run-1": ["semantic failure"]},
        }

        with patch.object(RUNNER, "evaluate_policy", return_value=evaluation) as evaluate:
            results = RUNNER.evaluate_variants(
                readers,
                matrix,
                repetitions=1,
                workers=1,
                run_budget=1,
                infrastructure_retries=0,
            )

        self.assertEqual(evaluate.call_count, 1)
        self.assertEqual(results["candidate"]["decision_source"], "identical-policy-alias")
        self.assertEqual(
            results["candidate"]["blocking_failures"],
            {"bounded#run-1": ["semantic failure"]},
        )

    def test_only_infrastructure_or_parse_errors_are_retried(self) -> None:
        valid = f"<eval-json>{json.dumps(passing_observed())}</eval-json>"
        results = [
            subprocess.CompletedProcess([], 0, stdout="not json", stderr=""),
            subprocess.CompletedProcess([], 0, stdout=valid, stderr=""),
        ]

        with patch.object(RUNNER.subprocess, "run", side_effect=results) as run:
            record = RUNNER.run_hermes_scenario(
                "prompt",
                run_budget=1,
                infrastructure_retries=1,
            )

        self.assertEqual(run.call_count, 2)
        self.assertEqual(record["attempts"], 2)
        self.assertEqual(record["observed"], passing_observed())
        self.assertEqual(len(record["infrastructure_errors"]), 1)

    def test_command_pins_deepseek_provider_and_model(self) -> None:
        valid = f"<eval-json>{json.dumps(passing_observed())}</eval-json>"
        completed = subprocess.CompletedProcess([], 0, stdout=valid, stderr="")

        with patch.object(RUNNER.subprocess, "run", return_value=completed) as run:
            RUNNER.run_hermes_scenario(
                "prompt",
                run_budget=1,
                infrastructure_retries=0,
            )

        command = run.call_args.args[0]
        self.assertEqual(
            command[command.index("--model") + 1],
            "deepseek-v4-flash",
        )
        self.assertEqual(
            command[command.index("--provider") + 1],
            "opencode-go",
        )


if __name__ == "__main__":
    unittest.main()
