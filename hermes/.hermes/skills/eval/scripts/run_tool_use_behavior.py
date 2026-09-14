from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed
from contextlib import nullcontext
from pathlib import Path
from threading import Lock
from typing import Any, Callable


BASELINE_REF = "e1d68989579d82927396c5c8f8f744c15d4caf87"
EXPECTED_MATRIX_SHA256 = "b41891ceafd847bdced91ef17bd7e7237f00007f1426b701a744f53d12f076dc"
SESSION_PATTERN = re.compile(r"session_id:\s*([A-Za-z0-9_-]+)")
DELEGATION_RUN_LOCK = Lock()


def run(command: list[str], **kwargs: Any) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, check=False, capture_output=True, text=True, **kwargs)


def git(repo: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return run(["git", *args], cwd=repo)


def sha256_bytes(content: bytes) -> str:
    return hashlib.sha256(content).hexdigest()


def matrix_sha256(path: Path) -> str:
    return sha256_bytes(path.read_bytes())


def fixture_sha256(matrix: dict[str, Any]) -> str:
    kinds = sorted({scenario["fixture"] for scenario in matrix["scenarios"]})
    material = b""
    for kind in kinds:
        for relative, content in sorted(fixture_files(kind).items()):
            material += kind.encode() + b"\0" + relative.encode() + b"\0" + content.encode() + b"\0"
    material += b"fixture-history\0marigold-envelope\0fixture-sentinel"
    return sha256_bytes(material)


def candidate_reader(skills_root: Path) -> Callable[[str], bytes]:
    contents = {
        str(path.relative_to(skills_root)): path.read_bytes()
        for path in skills_root.rglob("*")
        if path.is_file()
    }

    def read(relative: str) -> bytes:
        return contents[relative]

    return read


def baseline_reader(repo: Path, baseline_ref: str) -> Callable[[str], bytes]:
    def read(relative: str) -> bytes:
        result = git(repo, "show", f"{baseline_ref}:hermes/.hermes/skills/{relative}")
        if result.returncode != 0:
            raise RuntimeError(f"baseline missing {relative}: {result.stderr.strip()}")
        return result.stdout.encode()

    return read


def candidate_files(skills_root: Path) -> list[str]:
    return sorted(str(path.relative_to(skills_root)) for path in skills_root.rglob("*") if path.is_file())


def baseline_files(repo: Path, baseline_ref: str) -> list[str]:
    result = git(repo, "ls-tree", "-r", "--name-only", baseline_ref, "hermes/.hermes/skills")
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip())
    prefix = "hermes/.hermes/skills/"
    return sorted(line[len(prefix):] for line in result.stdout.splitlines() if line.startswith(prefix))


def policy_files(files: list[str]) -> list[str]:
    return [relative for relative in files if relative.endswith(".md")]


def bundle_sha256(files: list[str], read: Callable[[str], bytes]) -> str:
    material = b"".join(relative.encode() + b"\0" + read(relative) + b"\0" for relative in policy_files(files))
    return sha256_bytes(material)


def materialize_skills(home: Path, files: list[str], read: Callable[[str], bytes]) -> None:
    for relative in files:
        target = home / "skills" / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(read(relative))
    sentinel = home / "skills" / "fixture-sentinel" / "SKILL.md"
    sentinel.parent.mkdir(parents=True, exist_ok=True)
    sentinel.write_text(
        "---\nname: fixture-sentinel\ndescription: Synthetic catalog sentinel for isolated evaluation.\n"
        "disable-model-invocation: true\n---\n\n# Fixture Sentinel\n\n"
        "This synthetic skill proves that catalog discovery reads the isolated runtime inventory.\n"
    )


def fixture_files(kind: str) -> dict[str, str]:
    common = {
        "src/widget.py": "def render_widget(name: str) -> str:\n    return f\"widget:{name}\"\n",
        "tests/test_widget.py": (
            "import unittest\n\nfrom src.widget import render_widget\n\n\n"
            "class WidgetTests(unittest.TestCase):\n"
            "    def test_widget(self):\n"
            "        self.assertEqual(render_widget(\"probe\"), \"widget:probe\")\n"
        ),
        "README.md": "# Widget Fixture\n\nRun `python3 -m unittest discover -s tests` to verify it.\n",
    }
    if kind in {"architecture", "handoff", "catalog", "widget"}:
        return common
    if kind == "broad":
        return {
            **common,
            "src/request.py": (
                "from src.service import load_widget\n\n"
                "def handle_widget(name: str) -> str:\n"
                "    return load_widget(name)\n"
            ),
            "src/service.py": (
                "from src.storage import WidgetMissing, fetch_widget\n\n"
                "def load_widget(name: str) -> str:\n"
                "    try:\n        return fetch_widget(name)\n"
                "    except WidgetMissing:\n        return \"missing\"\n"
            ),
            "src/storage.py": (
                "class WidgetMissing(Exception):\n    pass\n\n"
                "def fetch_widget(name: str) -> str:\n"
                "    if name != \"probe\":\n        raise WidgetMissing(name)\n"
                "    return \"widget:probe\"\n"
            ),
        }
    if kind == "review":
        return {
            **common,
            "REVIEW.md": (
                "# Proposed change\n\nCatch every exception in render_widget, log the full name, "
                "and return an empty string. No regression test is proposed.\n"
            ),
        }
    raise ValueError(f"unknown fixture {kind!r}")


def initialize_fixture(root: Path, kind: str) -> None:
    for relative, content in fixture_files(kind).items():
        target = root / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
    if kind == "handoff":
        result = run(["git", "init", "-q"], cwd=root)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip())
        run(["git", "config", "user.email", "fixture@example.invalid"], cwd=root)
        run(["git", "config", "user.name", "Fixture Eval"], cwd=root)
        run(["git", "add", "."], cwd=root)
        committed = run(["git", "commit", "-qm", "fixture baseline"], cwd=root)
        if committed.returncode != 0:
            raise RuntimeError(committed.stderr.strip())


def snapshot(root: Path) -> dict[str, str]:
    return {
        str(path.relative_to(root)): sha256_bytes(path.read_bytes())
        for path in root.rglob("*")
        if path.is_file() and ".git" not in path.relative_to(root).parts
    }


def changed_paths(before: dict[str, str], after: dict[str, str]) -> set[str]:
    return {path for path in before.keys() | after.keys() if before.get(path) != after.get(path)}


def path_is_inside_roots(raw_path: Any, fixture: Path, roots: list[Path]) -> bool:
    if not isinstance(raw_path, str) or not raw_path.strip():
        return False
    path = Path(raw_path)
    resolved = path.resolve() if path.is_absolute() else (fixture / path).resolve()
    return any(resolved == root.resolve() or root.resolve() in resolved.parents for root in roots)


def path_is_inside_fixture(raw_path: Any, fixture: Path) -> bool:
    return path_is_inside_roots(raw_path, fixture, [fixture])


def write_config(home: Path, model: str, provider: str) -> None:
    home.mkdir(parents=True, exist_ok=True)
    home.joinpath("config.yaml").write_text(
        f"model:\n  default: {model}\n  provider: {provider}\n"
        "agent:\n  reasoning_effort: medium\n"
        f"delegation:\n  model: {model}\n  provider: {provider}\n"
        "  max_iterations: 24\n  max_concurrent_children: 4\n"
    )


def link_credentials(source_home: Path, target_home: Path) -> None:
    auth = source_home / "auth.json"
    if not auth.is_file():
        raise RuntimeError(f"credential store not found at {auth}")
    target_home.joinpath("auth.json").symlink_to(auth)
    env = source_home / ".env"
    if env.is_file():
        target_home.joinpath(".env").symlink_to(env)


def tool_schema_hashes(
    scenarios: list[dict[str, Any]], model: str, provider: str, hermes_python: Path,
) -> dict[str, str]:
    hashes: dict[str, str] = {}
    code = (
        "import json,sys\n"
        "import model_tools\n"
        "toolsets=sys.argv[1].split(',') if sys.argv[1] else []\n"
        "print(json.dumps(model_tools.get_tool_definitions(enabled_toolsets=toolsets, quiet_mode=True), "
        "sort_keys=True, separators=(',', ':')))\n"
    )
    with tempfile.TemporaryDirectory(prefix="tool-use-schema-") as temporary:
        home = Path(temporary)
        write_config(home, model, provider)
        environment = {**os.environ, "HERMES_HOME": str(home)}
        for toolsets in sorted({tuple(scenario["toolsets"]) for scenario in scenarios}):
            key = ",".join(toolsets)
            result = run([str(hermes_python), "-c", code, key], env=environment)
            if result.returncode != 0:
                raise RuntimeError(f"tool schema discovery failed for {key}: {result.stderr.strip()}")
            hashes[key] = sha256_bytes(result.stdout.strip().encode())
    return hashes


def seed_history(home: Path, fixture: Path, hermes_python: Path) -> None:
    code = (
        "import sqlite3\n"
        "from pathlib import Path\n"
        "from hermes_state import SessionDB\n"
        f"db=SessionDB(Path({str(home / 'state.db')!r}))\n"
        f"db.create_session('fixture-history', 'tool', cwd={str(fixture)!r})\n"
        "db.append_message('fixture-history', 'user', 'Choose the widget output format.')\n"
        "db.append_message('fixture-history', 'assistant', 'Settled decision: use marigold-envelope as the output format marker.')\n"
        "db.end_session('fixture-history', 'completed')\n"
        "db.close()\n"
        f"conn=sqlite3.connect({str(home / 'state.db')!r})\n"
        "conn.execute(\"UPDATE sessions SET title='fixture-history', title_source='fixture' WHERE id='fixture-history'\")\n"
        "conn.commit()\n"
        "conn.close()\n"
    )
    result = run([str(hermes_python), "-c", code], env={**os.environ, "HERMES_HOME": str(home)})
    if result.returncode != 0:
        raise RuntimeError(f"history seed failed: {result.stderr.strip()}")


def clarify_wrapper(path: Path) -> None:
    path.write_text(
        "import json, os, sys\n"
        "from pathlib import Path\n"
        "import cli\n"
        "original = cli._configure_quiet_agent\n"
        "def configure(agent):\n"
        "    original(agent)\n"
        "    def answer(question, choices, multi_select=False, questions=None):\n"
        "        if questions is not None:\n"
        "            answers = {}\n"
        "            for entry in questions:\n"
        "                options = entry.get('choices') or ['fixture answer']\n"
        "                answers[entry['qid']] = options[0]\n"
        "            return json.dumps({'answers': answers})\n"
        "        return (choices or ['fixture answer'])[0]\n"
        "    agent.clarify_callback = answer\n"
        "cli._configure_quiet_agent = configure\n"
        "fixture, prompt_path, model, provider, toolsets, skill, budget = sys.argv[1:]\n"
        "os.chdir(fixture)\n"
        "os.environ['TERMINAL_CWD'] = fixture\n"
        "cli.main(query=Path(prompt_path).read_text(), oneshot=True, quiet=True, ignore_rules=True, "
        "model=model, provider=provider, toolsets=toolsets, skills=[skill], max_turns=16, run_budget=int(budget))\n"
    )


def command_for(
    scenario: dict[str, Any], home: Path, fixture: Path, prompt_path: Path,
    model: str, provider: str, hermes_python: Path, run_budget: int,
) -> list[str]:
    toolsets = ",".join(scenario["toolsets"])
    if scenario.get("clarify_fixture"):
        wrapper = home / "clarify_eval.py"
        clarify_wrapper(wrapper)
        return [
            str(hermes_python), str(wrapper), str(fixture), str(prompt_path),
            model, provider, toolsets, scenario["skill"], str(run_budget),
        ]
    return [
        "hermes", "chat", "--query-file", str(prompt_path), "-Q", "--ignore-rules",
        "--source", "tool", "--max-turns", "16", "--run-budget", str(run_budget),
        "--model", model, "--provider", provider, "--toolsets", toolsets,
        "--skills", scenario["skill"], "--in", str(fixture),
    ]


def export_trace(home: Path, session_id: str, output: Path) -> None:
    result = run(
        [
            "hermes", "sessions", "export", "--format", "trace", "--session-id",
            session_id, str(output),
        ],
        env={**os.environ, "HERMES_HOME": str(home)},
    )
    if result.returncode != 0 or not output.is_file():
        raise RuntimeError(f"trace export failed: {result.stderr.strip() or result.stdout.strip()}")


def parse_trace(path: Path) -> dict[str, Any]:
    rows = []
    for number, line in enumerate(path.read_text().splitlines(), 1):
        try:
            row = json.loads(line)
        except json.JSONDecodeError as error:
            raise ValueError(f"malformed trace line {number}: {error}") from error
        if not isinstance(row, dict):
            raise ValueError(f"trace line {number} is not an object")
        rows.append(row)
    if not rows:
        raise ValueError("trace is empty")
    calls: list[dict[str, Any]] = []
    results: dict[str, str] = {}
    for row in rows:
        message = row.get("message")
        if not isinstance(message, dict):
            raise ValueError("trace message is malformed")
        content = message.get("content")
        blocks = content if isinstance(content, list) else []
        for block in blocks:
            if not isinstance(block, dict):
                continue
            if block.get("type") == "tool_use":
                calls.append({
                    "id": block.get("id"),
                    "name": block.get("name"),
                    "input": block.get("input"),
                })
            elif block.get("type") == "tool_result":
                results[str(block.get("tool_use_id"))] = str(block.get("content", ""))
    normalized: list[dict[str, Any]] = []
    for call in calls:
        identifier = call.get("id")
        if not isinstance(identifier, str) or identifier not in results:
            raise ValueError(f"tool call {identifier!r} has no executed result")
        call["result"] = results[identifier]
        normalized.append(call)
        if call.get("name") == "tool_call":
            nested_calls = call.get("input", {}).get("calls", [])
            if not isinstance(nested_calls, list):
                raise ValueError("tool_call input calls is malformed")
            for index, nested in enumerate(nested_calls):
                if not isinstance(nested, dict) or not isinstance(nested.get("name"), str):
                    raise ValueError("tool_call nested invocation is malformed")
                arguments = nested.get("arguments", {})
                if not isinstance(arguments, dict):
                    raise ValueError("tool_call nested arguments are malformed")
                normalized.append({
                    "id": f"{identifier}:{index}",
                    "name": nested["name"],
                    "input": arguments,
                    "result": results[identifier],
                    "via": "tool_call",
                })
    return {"rows": len(rows), "calls": normalized}


def result_succeeded(content: str) -> bool:
    text = content.strip()
    if not text:
        return False
    try:
        payload = json.loads(text)
    except json.JSONDecodeError:
        return re.match(r"^(error|failed|failure)\b", text, re.IGNORECASE) is None
    if not isinstance(payload, dict):
        return True
    if payload.get("error") or payload.get("success") is False:
        return False
    if payload.get("status") in {"error", "failed", "failure"}:
        return False
    exit_code = payload.get("exit_code")
    return not isinstance(exit_code, int) or exit_code == 0


def child_sessions(
    home: Path, parent_id: str, evidence_dir: Path, trace_prefix: str,
) -> list[dict[str, Any]]:
    with sqlite3.connect(home / "state.db") as db:
        rows = db.execute(
            "SELECT id, ended_at, end_reason, tool_call_count FROM sessions "
            "WHERE parent_session_id = ? ORDER BY started_at, id",
            (parent_id,),
        ).fetchall()
    children = []
    for index, (identifier, ended_at, end_reason, tool_count) in enumerate(rows, 1):
        trace_path = evidence_dir / f"{trace_prefix}-child-{index}.trace.jsonl"
        export_trace(home, str(identifier), trace_path)
        trace = parse_trace(trace_path)
        children.append({
            "id": str(identifier),
            "completed": ended_at is not None,
            "end_reason": end_reason,
            "tool_call_count": int(tool_count or 0),
            "trace": str(trace_path),
            "tool_calls": [call["name"] for call in trace["calls"]],
        })
    return children


def evaluate(
    scenario: dict[str, Any], trace: dict[str, Any], stdout: str,
    before: dict[str, str], after: dict[str, str], fixture: Path,
    children: list[dict[str, Any]], read_roots: list[Path] | None = None,
) -> list[str]:
    failures: list[str] = []
    calls = trace["calls"]
    by_name: dict[str, list[dict[str, Any]]] = {}
    for call in calls:
        by_name.setdefault(str(call.get("name")), []).append(call)
    for name, minimum in scenario.get("required_tools", {}).items():
        successful = sum(result_succeeded(call["result"]) for call in by_name.get(name, []))
        if successful < minimum:
            failures.append(f"{name} successful calls expected >= {minimum}, got {successful}")
    for name in scenario.get("forbidden_tools", []):
        if by_name.get(name):
            failures.append(f"forbidden tool {name} executed {len(by_name[name])} time(s)")
    for name, field in {"read_file": "path", "search_files": "path"}.items():
        for call in by_name.get(name, []):
            raw_path = call.get("input", {}).get(field, "." if name == "search_files" else None)
            if not path_is_inside_roots(raw_path, fixture, read_roots or [fixture]):
                failures.append(f"{name} accessed path outside fixture or allowed read roots: {raw_path!r}")
    for name, field in {"write_file": "path", "patch": "path"}.items():
        for call in by_name.get(name, []):
            raw_path = call.get("input", {}).get(field)
            if not path_is_inside_fixture(raw_path, fixture):
                failures.append(f"{name} accessed path outside fixture: {raw_path!r}")
    minimum_children = scenario.get("minimum_children", 0)
    completed_children = [child for child in children if child["completed"]]
    if len(completed_children) < minimum_children:
        failures.append(
            f"completed independent child sessions expected >= {minimum_children}, "
            f"got {len(completed_children)}"
        )
    minimum_child_calls = scenario.get("minimum_child_tool_calls", 0)
    if minimum_child_calls:
        insufficient = [
            child["id"] for child in completed_children[:minimum_children]
            if child["tool_call_count"] < minimum_child_calls
        ]
        if insufficient:
            failures.append(
                f"child sessions below {minimum_child_calls} executed tool call(s): {insufficient}"
            )
    required_child_tools = set(scenario.get("required_child_tools_any", []))
    if required_child_tools:
        missing_tools = [
            child["id"] for child in completed_children[:minimum_children]
            if not required_child_tools.intersection(child["tool_calls"])
        ]
        if missing_tools:
            failures.append(
                f"child sessions did not execute any of {sorted(required_child_tools)}: {missing_tools}"
            )
    clarify_min = scenario.get("clarify_min_questions")
    if clarify_min is not None:
        clarify_calls = by_name.get("clarify", [])
        if clarify_calls:
            questions = clarify_calls[0].get("input", {}).get("questions", [])
            if not isinstance(questions, list) or len(questions) < clarify_min:
                failures.append(f"clarify questions expected >= {clarify_min}, got {len(questions) if isinstance(questions, list) else 0}")
    combined_results = "\n".join(call["result"] for call in calls)
    for text in scenario.get("required_result_text", []):
        if text not in combined_results and text not in stdout:
            failures.append(f"required result text {text!r} not observed")
    for pattern in scenario.get("required_result_patterns", []):
        if not re.search(pattern, stdout, re.IGNORECASE):
            failures.append(f"required final-response pattern {pattern!r} not observed")
    changes = changed_paths(before, after)
    allowed = set(scenario.get("allowed_writes", []))
    unexpected = sorted(changes - allowed)
    if unexpected:
        failures.append(f"unexpected fixture writes {unexpected}")
    for relative, fragments in scenario.get("required_artifacts", {}).items():
        path = fixture / relative
        if not path.is_file():
            failures.append(f"required artifact {relative!r} missing")
            continue
        content = path.read_text()
        for fragment in fragments:
            if fragment not in content:
                failures.append(f"required artifact {relative!r} missing {fragment!r}")
    return failures


def execute_once(
    variant: str, repetition: int, scenario: dict[str, Any], files: list[str],
    read: Callable[[str], bytes], source_home: Path, evidence_dir: Path,
    model: str, provider: str, infrastructure_retries: int, run_budget: int,
) -> dict[str, Any]:
    hermes_path = Path(shutil.which("hermes") or "")
    if not hermes_path:
        raise RuntimeError("hermes executable not found")
    hermes_python = hermes_path.resolve().parent / "python"
    infrastructure_errors: list[str] = []
    for attempt in range(1, infrastructure_retries + 2):
        with tempfile.TemporaryDirectory(prefix=f"tool-use-{variant}-{scenario['id']}-") as temporary:
            root = Path(temporary)
            home = root / "home"
            fixture = root / "fixture"
            try:
                fixture.mkdir()
                write_config(home, model, provider)
                link_credentials(source_home, home)
                materialize_skills(home, files, read)
                initialize_fixture(fixture, scenario["fixture"])
                if scenario["fixture"] == "handoff":
                    seed_history(home, fixture, hermes_python)
            except (RuntimeError, OSError, ValueError) as error:
                infrastructure_errors.append(f"attempt {attempt}: setup failed: {error}")
                continue
            prompt_path = root / "prompt.txt"
            prompt_path.write_text(scenario["prompt"] + "\n")
            before = snapshot(fixture)
            command = command_for(
                scenario, home, fixture, prompt_path, model, provider, hermes_python, run_budget
            )
            try:
                delegation_guard = (
                    DELEGATION_RUN_LOCK
                    if "delegation" in scenario["toolsets"]
                    else nullcontext()
                )
                with delegation_guard:
                    result = run(
                        command,
                        cwd=fixture,
                        env={**os.environ, "HERMES_HOME": str(home)},
                        timeout=run_budget + 40,
                    )
            except subprocess.TimeoutExpired:
                infrastructure_errors.append(
                    f"attempt {attempt}: execution exceeded {run_budget + 40}s process timeout"
                )
                continue
            match = SESSION_PATTERN.search(result.stdout + "\n" + result.stderr)
            if result.returncode != 0 or match is None:
                infrastructure_errors.append(
                    f"attempt {attempt}: exit={result.returncode}, "
                    f"session={bool(match)}, stderr={result.stderr.strip()[-500:]!r}, "
                    f"stdout={result.stdout.strip()[-500:]!r}"
                )
                continue
            session_id = match.group(1)
            trace_name = f"{variant}-{scenario['id']}-run-{repetition}-attempt-{attempt}.trace.jsonl"
            trace_path = evidence_dir / trace_name
            try:
                export_trace(home, session_id, trace_path)
                trace = parse_trace(trace_path)
                children = child_sessions(
                    home, session_id, evidence_dir, trace_path.name.removesuffix(".trace.jsonl")
                )
            except (RuntimeError, ValueError, OSError) as error:
                infrastructure_errors.append(f"attempt {attempt}: {error}")
                continue
            after = snapshot(fixture)
            available_read_roots = {"fixture": fixture, "home": home, "sandbox": root}
            requested_read_roots = scenario.get("allowed_read_roots", ["fixture"])
            unknown_read_roots = set(requested_read_roots) - available_read_roots.keys()
            if unknown_read_roots:
                infrastructure_errors.append(
                    f"attempt {attempt}: unknown allowed read roots {sorted(unknown_read_roots)}"
                )
                continue
            read_roots = [available_read_roots[name] for name in requested_read_roots]
            failures = evaluate(
                scenario, trace, result.stdout, before, after, fixture, children, read_roots
            )
            return {
                "variant": variant,
                "scenario": scenario["id"],
                "repetition": repetition,
                "attempts": attempt,
                "session_id": session_id,
                "trace": str(trace_path),
                "tool_calls": [call["name"] for call in trace["calls"]],
                "child_sessions": children,
                "changed_paths": sorted(changed_paths(before, after)),
                "infrastructure_errors": infrastructure_errors,
                "failures": failures,
                "final_response": result.stdout.strip(),
            }
    return {
        "variant": variant,
        "scenario": scenario["id"],
        "repetition": repetition,
        "attempts": infrastructure_retries + 1,
        "session_id": None,
        "trace": None,
        "tool_calls": [],
        "child_sessions": [],
        "changed_paths": [],
        "infrastructure_errors": infrastructure_errors,
        "failures": ["no authoritative trace after infrastructure retries"],
        "final_response": "",
    }


def summarize(runs: list[dict[str, Any]]) -> dict[str, Any]:
    failures = {
        f"{run['scenario']}#run-{run['repetition']}": run["failures"]
        for run in runs if run["failures"]
    }
    return {
        "runs": sorted(runs, key=lambda item: (item["scenario"], item["repetition"])),
        "failures": failures,
        "passed": not failures,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--baseline-ref", default=BASELINE_REF)
    parser.add_argument("--candidate-only", action="store_true")
    parser.add_argument("--repetitions", type=int, default=3)
    parser.add_argument("--workers", type=int, default=2)
    parser.add_argument("--scenario", action="append")
    parser.add_argument("--model", default="gpt-5.6-sol")
    parser.add_argument("--provider", default="openai-codex")
    parser.add_argument("--run-budget", type=int, default=360)
    parser.add_argument("--infrastructure-retries", type=int, default=1)
    parser.add_argument("--credential-home", type=Path, default=Path(os.environ.get("HERMES_HOME", "~/.hermes")).expanduser())
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    if args.repetitions < 1 or args.workers < 1 or args.run_budget < 1:
        raise RuntimeError("repetitions, workers, and run budget must be positive")
    if args.infrastructure_retries not in {0, 1}:
        raise RuntimeError("infrastructure retries must be 0 or 1")
    script_path = Path(__file__).resolve()
    runner_hash = sha256_bytes(script_path.read_bytes())
    repo = script_path.parents[5]
    skills_root = script_path.parents[2]
    matrix_path = script_path.parents[1] / "references" / "tool-use-scenarios.json"
    actual_matrix_hash = matrix_sha256(matrix_path)
    if actual_matrix_hash != EXPECTED_MATRIX_SHA256:
        raise RuntimeError(
            f"scenario matrix hash expected {EXPECTED_MATRIX_SHA256}, got {actual_matrix_hash}"
        )
    matrix = json.loads(matrix_path.read_text())
    scenarios = matrix["scenarios"]
    if args.scenario:
        selected = set(args.scenario)
        scenarios = [scenario for scenario in scenarios if scenario["id"] in selected]
        missing = selected - {scenario["id"] for scenario in scenarios}
        if missing:
            raise RuntimeError(f"unknown scenarios: {sorted(missing)}")
    output = args.output or script_path.parents[1] / "reports" / "tool-use-behavior.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    evidence_dir = output.parent / f"{output.stem}-traces"
    evidence_dir.mkdir(parents=True, exist_ok=True)
    variants: list[tuple[str, list[str], Callable[[str], bytes]]] = []
    if not args.candidate_only:
        base_files = baseline_files(repo, args.baseline_ref)
        variants.append(("baseline", base_files, baseline_reader(repo, args.baseline_ref)))
    current_files = candidate_files(skills_root)
    variants.append(("candidate", current_files, candidate_reader(skills_root)))
    hermes_path = Path(shutil.which("hermes") or "")
    if not hermes_path:
        raise RuntimeError("hermes executable not found")
    hermes_python = hermes_path.resolve().parent / "python"
    schema_hashes = tool_schema_hashes(scenarios, args.model, args.provider, hermes_python)
    jobs = [
        (variant, repetition, scenario, files, reader)
        for repetition in range(1, args.repetitions + 1)
        for scenario in scenarios
        for variant, files, reader in variants
    ]
    runs_by_variant: dict[str, list[dict[str, Any]]] = {variant: [] for variant, _, _ in variants}
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = [
            pool.submit(
                execute_once, variant, repetition, scenario, files, reader,
                args.credential_home, evidence_dir, args.model, args.provider,
                args.infrastructure_retries, args.run_budget,
            )
            for variant, repetition, scenario, files, reader in jobs
        ]
        for future in as_completed(futures):
            record = future.result()
            runs_by_variant[record["variant"]].append(record)
            state = "PASS" if not record["failures"] else "FAIL"
            print(f"{state} {record['variant']} {record['scenario']} run {record['repetition']}", flush=True)
    report_variants = {variant: summarize(runs) for variant, runs in runs_by_variant.items()}
    policy = {
        variant: {
            "sha256": bundle_sha256(files, reader),
            "files": policy_files(files),
        }
        for variant, files, reader in variants
    }
    report = {
        "baseline_ref": None if args.candidate_only else args.baseline_ref,
        "model": args.model,
        "provider": args.provider,
        "delegation": {"model": args.model, "provider": args.provider},
        "credential_strategy": "source-home symlinks inside disposable HERMES_HOME directories",
        "runtime": run(["hermes", "--version"]).stdout.strip(),
        "repetitions": args.repetitions,
        "workers": args.workers,
        "delegation_parent_concurrency": 1,
        "run_budget_seconds": args.run_budget,
        "infrastructure_retries": args.infrastructure_retries,
        "scenario_ids": [scenario["id"] for scenario in scenarios],
        "tool_schema_sha256": schema_hashes,
        "fixture_sha256": fixture_sha256(matrix),
        "matrix_sha256": actual_matrix_hash,
        "runner_sha256": runner_hash,
        "policy": policy,
        "variants": report_variants,
    }
    output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"report: {output}")
    candidate = report_variants["candidate"]
    return 0 if candidate["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
