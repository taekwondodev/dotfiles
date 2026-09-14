from __future__ import annotations

import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "scripts" / "run_tool_use_behavior.py"
SPEC = importlib.util.spec_from_file_location("run_tool_use_behavior", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
RUNNER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RUNNER)


def trace_call(name: str, result: object = None, **arguments: object) -> dict[str, object]:
    payload = {"success": True} if result is None else result
    return {
        "id": f"call-{name}",
        "name": name,
        "input": arguments,
        "result": json.dumps(payload),
    }


class ToolUseRunnerTests(unittest.TestCase):
    def test_parse_trace_requires_executed_result(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "trace.jsonl"
            path.write_text(json.dumps({
                "message": {"content": [{
                    "type": "tool_use",
                    "id": "call-1",
                    "name": "read_file",
                    "input": {"path": "src/widget.py"},
                }]}
            }) + "\n")

            with self.assertRaisesRegex(ValueError, "no executed result"):
                RUNNER.parse_trace(path)

    def test_parse_trace_normalizes_deferred_tool_execution(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "trace.jsonl"
            path.write_text("\n".join([
                json.dumps({"message": {"content": [{
                    "type": "tool_use",
                    "id": "call-1",
                    "name": "tool_call",
                    "input": {"calls": [{"name": "todo_list", "arguments": {}}]},
                }]}}),
                json.dumps({"message": {"content": [{
                    "type": "tool_result",
                    "tool_use_id": "call-1",
                    "content": json.dumps({"success": True}),
                }]}}),
            ]) + "\n")

            trace = RUNNER.parse_trace(path)

        self.assertEqual([call["name"] for call in trace["calls"]], ["tool_call", "todo_list"])
        self.assertEqual(trace["calls"][1]["via"], "tool_call")

    def test_parse_trace_rejects_malformed_jsonl(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "trace.jsonl"
            path.write_text('{"message":\n')

            with self.assertRaisesRegex(ValueError, "malformed trace line"):
                RUNNER.parse_trace(path)

    def test_model_prose_does_not_count_as_a_tool_call(self) -> None:
        scenario = {"required_tools": {"read_file": 1}, "allowed_writes": []}
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            failures = RUNNER.evaluate(
                scenario,
                {"calls": []},
                "I used read_file successfully.",
                {},
                {},
                fixture,
                [],
            )

        self.assertIn("read_file successful calls expected >= 1, got 0", failures)

    def test_unsuccessful_required_action_fails(self) -> None:
        scenario = {"required_tools": {"read_file": 1}, "allowed_writes": []}
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            failures = RUNNER.evaluate(
                scenario,
                {"calls": [trace_call("read_file", {"error": "denied"}, path="src/widget.py")]},
                "",
                {},
                {},
                fixture,
                [],
            )

        self.assertIn("read_file successful calls expected >= 1, got 0", failures)

    def test_plain_error_result_fails(self) -> None:
        self.assertFalse(RUNNER.result_succeeded("Error: permission denied"))
        self.assertFalse(RUNNER.result_succeeded(""))
        self.assertTrue(RUNNER.result_succeeded("file contents"))

    def test_path_outside_fixture_fails(self) -> None:
        scenario = {"required_tools": {"read_file": 1}, "allowed_writes": []}
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory) / "fixture"
            fixture.mkdir()
            failures = RUNNER.evaluate(
                scenario,
                {"calls": [trace_call("read_file", path="../outside.txt")]},
                "",
                {},
                {},
                fixture,
                [],
            )

        self.assertTrue(any("outside fixture" in failure for failure in failures))

    def test_read_only_tool_can_use_explicit_additional_root(self) -> None:
        scenario = {"required_tools": {"search_files": 1}, "allowed_writes": []}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / "fixture"
            history = root / "home"
            fixture.mkdir()
            history.mkdir()
            failures = RUNNER.evaluate(
                scenario,
                {"calls": [trace_call("search_files", path=str(history), pattern="fixture-history")]},
                "",
                {},
                {},
                fixture,
                [],
                read_roots=[fixture, history],
            )

        self.assertFalse(any("outside fixture" in failure for failure in failures))

    def test_write_tool_stays_fixture_bound_when_read_root_is_broader(self) -> None:
        scenario = {"allowed_writes": []}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            fixture = root / "fixture"
            history = root / "home"
            fixture.mkdir()
            history.mkdir()
            failures = RUNNER.evaluate(
                scenario,
                {"calls": [trace_call("write_file", path=str(history / "HANDOFF.md"), content="bad")]},
                "",
                {},
                {},
                fixture,
                [],
                read_roots=[fixture, history],
            )

        self.assertTrue(any("write_file accessed path outside fixture" in failure for failure in failures))

    def test_missing_independent_children_fails(self) -> None:
        scenario = {"minimum_children": 2, "allowed_writes": []}
        with tempfile.TemporaryDirectory() as directory:
            failures = RUNNER.evaluate(
                scenario,
                {"calls": []},
                "",
                {},
                {},
                Path(directory),
                [{"id": "only-child", "completed": True, "end_reason": "completed", "tool_call_count": 1}],
            )

        self.assertIn("completed independent child sessions expected >= 2, got 1", failures)

    def test_child_self_report_without_executed_tool_calls_fails(self) -> None:
        scenario = {"minimum_children": 1, "minimum_child_tool_calls": 1, "allowed_writes": []}
        child = {"id": "child", "completed": True, "end_reason": "completed", "tool_call_count": 0}
        with tempfile.TemporaryDirectory() as directory:
            failures = RUNNER.evaluate(
                scenario, {"calls": []}, "child says it inspected files", {}, {}, Path(directory), [child]
            )

        self.assertIn("child sessions below 1 executed tool call(s): ['child']", failures)

    def test_child_without_required_file_execution_fails(self) -> None:
        scenario = {
            "minimum_children": 1,
            "required_child_tools_any": ["search_files", "read_file"],
            "allowed_writes": [],
        }
        child = {
            "id": "child",
            "completed": True,
            "end_reason": "completed",
            "tool_call_count": 1,
            "tool_calls": ["skills_list"],
        }
        with tempfile.TemporaryDirectory() as directory:
            failures = RUNNER.evaluate(
                scenario, {"calls": []}, "", {}, {}, Path(directory), [child]
            )

        self.assertTrue(any("did not execute any" in failure for failure in failures))

    def test_forbidden_fixture_write_fails(self) -> None:
        scenario = {"allowed_writes": []}
        before = {"src/widget.py": "before"}
        after = {"src/widget.py": "after"}
        with tempfile.TemporaryDirectory() as directory:
            failures = RUNNER.evaluate(
                scenario,
                {"calls": []},
                "",
                before,
                after,
                Path(directory),
                [],
            )

        self.assertIn("unexpected fixture writes ['src/widget.py']", failures)

    def test_clarify_requires_one_batched_multi_question_call(self) -> None:
        scenario = {
            "required_tools": {"clarify": 1},
            "clarify_min_questions": 2,
            "allowed_writes": [],
        }
        call = trace_call(
            "clarify",
            questions=[{"question": "Only one?", "choices": ["A", "B"]}],
        )
        with tempfile.TemporaryDirectory() as directory:
            failures = RUNNER.evaluate(
                scenario,
                {"calls": [call]},
                "",
                {},
                {},
                Path(directory),
                [],
            )

        self.assertIn("clarify questions expected >= 2, got 1", failures)

    def test_scenario_expectations_are_not_part_of_prompt(self) -> None:
        scenario = {
            "prompt": "Inspect the fixture.",
            "required_tools": {"read_file": 1},
            "required_result_text": ["secret expected token"],
        }

        self.assertEqual(scenario["prompt"], "Inspect the fixture.")
        self.assertNotIn("secret expected token", scenario["prompt"])


if __name__ == "__main__":
    unittest.main()
