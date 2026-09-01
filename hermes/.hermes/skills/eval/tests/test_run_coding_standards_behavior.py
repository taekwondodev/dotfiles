from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path
from unittest.mock import patch


SCRIPTS = Path(__file__).parents[1] / "scripts"
DEV_SPEC = importlib.util.spec_from_file_location(
    "run_dev_cycle_behavior", SCRIPTS / "run_dev_cycle_behavior.py"
)
assert DEV_SPEC is not None and DEV_SPEC.loader is not None
DEV_RUNNER = importlib.util.module_from_spec(DEV_SPEC)
DEV_SPEC.loader.exec_module(DEV_RUNNER)
sys.modules["run_dev_cycle_behavior"] = DEV_RUNNER

SCRIPT = SCRIPTS / "run_coding_standards_behavior.py"
SPEC = importlib.util.spec_from_file_location("run_coding_standards_behavior", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


class CodingStandardsBehaviorRunnerTests(unittest.TestCase):
    def test_compare_accepts_exact_expected_behavior(self) -> None:
        expectation = {
            "validate_intrinsic_at_entry": True,
            "intrinsic_invariants_owned_by_types": True,
            "contextual_rules_owned_by_stateful_decider": True,
            "repeat_internal_validation": False,
            "recompute_established_facts": None,
            "decompose_by_domain_responsibility": None,
            "extract_only_to_satisfy_metric": False,
            "required_architecture_styles": [],
        }
        matrix = {
            "scenarios": [
                {"id": "registration", "prompt": "register", "expect": expectation}
            ]
        }
        observed = [{"id": "registration", "actions": ["construct types"], **expectation}]

        self.assertEqual(RUNNER.compare(matrix, observed), {})

    def test_compare_rejects_revalidation_and_forced_architecture(self) -> None:
        expectation = {
            "validate_intrinsic_at_entry": True,
            "intrinsic_invariants_owned_by_types": True,
            "contextual_rules_owned_by_stateful_decider": True,
            "repeat_internal_validation": False,
            "recompute_established_facts": None,
            "decompose_by_domain_responsibility": None,
            "extract_only_to_satisfy_metric": False,
            "required_architecture_styles": [],
        }
        matrix = {
            "scenarios": [
                {"id": "registration", "prompt": "register", "expect": expectation}
            ]
        }
        observed = [
            {
                "id": "registration",
                "actions": ["revalidate in service"],
                **expectation,
                "repeat_internal_validation": True,
                "required_architecture_styles": ["hexagonal"],
            }
        ]

        failures = RUNNER.compare(matrix, observed)["registration"]
        self.assertTrue(any("repeat_internal_validation" in failure for failure in failures))
        self.assertTrue(any("required_architecture_styles" in failure for failure in failures))

    def test_compare_rejects_malformed_unpinned_field(self) -> None:
        expectation = {
            "decompose_by_domain_responsibility": True,
            "extract_only_to_satisfy_metric": False,
            "required_architecture_styles": [],
        }
        observed = {
            "id": "complexity",
            "actions": ["flatten branches"],
            "validate_intrinsic_at_entry": None,
            "intrinsic_invariants_owned_by_types": None,
            "contextual_rules_owned_by_stateful_decider": None,
            "repeat_internal_validation": None,
            "recompute_established_facts": "no",
            "decompose_by_domain_responsibility": True,
            "extract_only_to_satisfy_metric": False,
            "required_architecture_styles": [],
        }
        matrix = {
            "scenarios": [
                {"id": "complexity", "prompt": "simplify", "expect": expectation}
            ]
        }

        failures = RUNNER.compare(matrix, [observed])["complexity"]
        self.assertIn("recompute_established_facts must be boolean or null", failures)

    def test_identical_policy_bundles_share_one_decision(self) -> None:
        matrix = {"scenarios": []}
        readers = [
            ("baseline", lambda relative: "same"),
            ("candidate", lambda relative: "same"),
        ]

        with (
            patch.object(RUNNER, "run_hermes", return_value=[]) as run_hermes,
            patch.object(RUNNER, "compare", return_value={}),
        ):
            results = RUNNER.evaluate_variants(
                readers,
                matrix,
                run_budget=1,
                model=None,
                provider=None,
            )

        self.assertEqual(run_hermes.call_count, 1)
        self.assertEqual(results["candidate"]["decision_source"], "identical-policy-alias")
        self.assertEqual(results["candidate"]["policy_alias_of"], "baseline")
        self.assertEqual(results["candidate"]["blocking_failures"], {})

    def test_different_candidate_policy_failure_is_blocking(self) -> None:
        matrix = {"scenarios": []}
        readers = [
            ("baseline", lambda relative: "baseline"),
            ("candidate", lambda relative: "candidate"),
        ]

        with (
            patch.object(RUNNER, "run_hermes", side_effect=[[], []]),
            patch.object(
                RUNNER,
                "compare",
                side_effect=[{}, {"scenario": ["candidate failure"]}],
            ),
        ):
            results = RUNNER.evaluate_variants(
                readers,
                matrix,
                run_budget=1,
                model=None,
                provider=None,
            )

        self.assertEqual(results["candidate"]["decision_source"], "fresh-run")
        self.assertEqual(
            results["candidate"]["blocking_failures"],
            {"scenario": ["candidate failure"]},
        )


if __name__ == "__main__":
    unittest.main()
