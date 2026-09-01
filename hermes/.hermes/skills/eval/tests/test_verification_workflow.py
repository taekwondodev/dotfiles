from __future__ import annotations

import unittest
from pathlib import Path


SKILLS = Path(__file__).parents[2]


class VerificationWorkflowTests(unittest.TestCase):
    def read_skill(self, name: str) -> str:
        return (SKILLS / name / "SKILL.md").read_text()

    def test_create_is_model_invoked_and_generates_project_skill(self) -> None:
        content = self.read_skill("create-verification-skill")

        self.assertNotIn("disable-model-invocation: true", content)
        self.assertIn(".hermes/skills/verify-<app>/SKILL.md", content)
        self.assertIn("hermes skills trust <repo-root>", content)
        self.assertIn("a fresh Hermes process", content)
        self.assertIn("Do not set `disable-model-invocation`", content)
        self.assertNotIn(".cursor/", content)

    def test_maintain_is_user_invoked_and_write_scoped(self) -> None:
        content = self.read_skill("maintain-verification-skill")

        self.assertIn("disable-model-invocation: true", content)
        self.assertIn("Edit only the selected verification-skill directory", content)
        self.assertIn("never owns product fixes or delivery", content)

    def test_prove_it_works_owns_project_verification_selection(self) -> None:
        content = self.read_skill("principle-prove-it-works")

        for needle in (
            "## Project verification skills",
            "inspect the project skill index",
            "behavior outside the skill's mapped surface",
            "A verification skill complements tests",
            "Doctor`, isolation, drive, evidence, and cleanup",
        ):
            self.assertIn(needle, content)

    def test_direct_capabilities_point_to_canonical_owner(self) -> None:
        for name in ("investigation", "blast-radius", "perf-issue", "hillclimb"):
            with self.subTest(skill=name):
                content = self.read_skill(name)
                self.assertIn("principle-prove-it-works", content)
                self.assertNotIn("## Project verification skills", content)

    def test_setup_offers_generation_without_agents_pointer(self) -> None:
        content = self.read_skill("dev-cycle-setup")

        self.assertIn("### 6. Offer runtime verification", content)
        self.assertIn("load `create-verification-skill`", content)
        self.assertIn("On decline, finish without placeholders", content)
        self.assertIn("Do not copy its path or procedure into `AGENTS.md`", content)


if __name__ == "__main__":
    unittest.main()
