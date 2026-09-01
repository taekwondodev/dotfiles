from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPT = Path(__file__).parents[1] / "scripts" / "run_dev_cycle_behavior.py"
SPEC = importlib.util.spec_from_file_location("run_dev_cycle_behavior", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class DevCycleBehaviorRunnerTests(unittest.TestCase):
    def test_prompt_does_not_name_policy_variant(self) -> None:
        matrix = {"scenarios": []}
        prompt = RUNNER.build_prompt(matrix, lambda relative: f"policy:{relative}")

        self.assertNotIn("Policy variant", prompt)
        self.assertNotIn("baseline", prompt)
        self.assertNotIn("candidate", prompt)

    def test_identical_policy_bundles_share_one_fresh_decision(self) -> None:
        matrix = {"scenarios": []}
        readers = [
            ("baseline", lambda relative: f"same:{relative}"),
            ("candidate", lambda relative: f"same:{relative}"),
        ]
        observed: list[dict[str, object]] = []

        with (
            patch.object(RUNNER, "run_hermes", return_value=observed) as run_hermes,
            patch.object(
                RUNNER,
                "compare",
                return_value={"shared-scenario": ["shared failure"]},
            ),
        ):
            results = RUNNER.evaluate_variants(
                readers,
                matrix,
                known_skills=set(),
                run_budget=1,
                model=None,
                provider=None,
            )

        self.assertEqual(run_hermes.call_count, 1)
        self.assertEqual(results["baseline"]["decision_source"], "fresh-run")
        self.assertEqual(results["candidate"]["decision_source"], "identical-policy-alias")
        self.assertEqual(results["candidate"]["policy_alias_of"], "baseline")
        self.assertEqual(results["candidate"]["blocking_failures"], {})
        self.assertEqual(
            results["candidate"]["failures"],
            {"shared-scenario": ["shared failure"]},
        )
        self.assertEqual(
            results["baseline"]["policy_sha256"],
            results["candidate"]["policy_sha256"],
        )

    def test_different_policy_bundles_get_fresh_decisions(self) -> None:
        matrix = {"scenarios": []}
        readers = [
            ("baseline", lambda relative: f"baseline:{relative}"),
            ("candidate", lambda relative: f"candidate:{relative}"),
        ]

        with (
            patch.object(RUNNER, "run_hermes", side_effect=[[], []]) as run_hermes,
            patch.object(
                RUNNER,
                "compare",
                side_effect=[
                    {"baseline-scenario": ["baseline failure"]},
                    {"candidate-scenario": ["candidate failure"]},
                ],
            ),
        ):
            results = RUNNER.evaluate_variants(
                readers,
                matrix,
                known_skills=set(),
                run_budget=1,
                model=None,
                provider=None,
            )

        self.assertEqual(run_hermes.call_count, 2)
        self.assertEqual(results["baseline"]["decision_source"], "fresh-run")
        self.assertEqual(results["candidate"]["decision_source"], "fresh-run")
        self.assertEqual(
            results["candidate"]["blocking_failures"],
            {"candidate-scenario": ["candidate failure"]},
        )
        self.assertNotEqual(
            results["baseline"]["policy_sha256"],
            results["candidate"]["policy_sha256"],
        )


if __name__ == "__main__":
    unittest.main()
