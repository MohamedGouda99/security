#!/usr/bin/env python3
"""Advanced security pipeline runner.

Features:
- Structured configuration for each check (command, cwd, required files).
- Optional terraform plan generation feeding OPA evaluation.
- Streaming output with real-time logging and colorized status markers.
- JSON + Markdown report summarizing pass/fail state.
- Graceful cleanup for temporary plan artifacts and helpful remediation hints.
"""
from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

try:
    from rich.console import Console
    from rich.table import Table
    from rich.text import Text
except ImportError:  # fallback when rich is unavailable
    Console = None  # type: ignore

ROOT = Path(__file__).resolve().parents[1]
POLICY_DIR = ROOT / "policies"
INFRA_DIR = ROOT / "infra"
DEV_ENV = INFRA_DIR / "envs" / "dev"
REPORT_DIR = ROOT / "reports"


@dataclass
class CheckResult:
    command: List[str]
    cwd: Path
    returncode: int
    stdout: str
    stderr: str
    duration: float
    hint: Optional[str] = None

    @property
    def name(self) -> str:
        return " ".join(self.command)

    @property
    def passed(self) -> bool:
        return self.returncode == 0


@dataclass
class Check:
    command: List[str]
    cwd: Path
    description: str
    hint: Optional[str] = None
    ensure_file: Optional[Path] = None
    env: Dict[str, str] = field(default_factory=dict)

    def run(self) -> CheckResult:
        start = datetime.now()
        merged_env = dict(**self.env)
        merged_env.update({k: v for k, v in (('PYTHONUTF8', '1'),)})

        process = subprocess.run(
            self.command,
            cwd=self.cwd,
            env={**merged_env, **dict(**{k: v for k, v in dict(**merged_env).items()})},
            capture_output=True,
            text=True,
        )
        duration = (datetime.now() - start).total_seconds()
        return CheckResult(
            command=self.command,
            cwd=self.cwd,
            returncode=process.returncode,
            stdout=process.stdout,
            stderr=process.stderr,
            duration=duration,
            hint=self.hint,
        )


def ensure_dependencies(commands: List[str]) -> None:
    missing = [cmd for cmd in commands if shutil.which(cmd) is None]
    if missing:
        sys.exit(f"Missing required tools: {', '.join(missing)}")


def generate_plan(plan_path: Path) -> CheckResult:
    cmd = [
        "terraform",
        "plan",
        "-out",
        str(plan_path),
    ]
    start = datetime.now()
    proc = subprocess.run(cmd, cwd=DEV_ENV, capture_output=True, text=True)
    duration = (datetime.now() - start).total_seconds()
    return CheckResult(cmd, DEV_ENV, proc.returncode, proc.stdout, proc.stderr, duration)


def convert_plan_to_json(plan_path: Path, json_path: Path) -> CheckResult:
    cmd = [
        "terraform",
        "show",
        "-json",
        str(plan_path),
    ]
    start = datetime.now()
    proc = subprocess.run(cmd, cwd=DEV_ENV, capture_output=True, text=True)
    duration = (datetime.now() - start).total_seconds()
    if proc.returncode == 0:
        json_path.write_text(proc.stdout, encoding="utf-8")
    return CheckResult(cmd, DEV_ENV, proc.returncode, proc.stdout, proc.stderr, duration)


def build_checks(plan_json: Path) -> List[Check]:
    return [
        Check(
            [sys.executable, "-m", "pip", "install", "-e", f"{ROOT / 'app'}[dev]"],
            ROOT,
            "Install dev dependencies for app",
        ),
        Check(["ruff", "check", str(ROOT / "app" / "src")], ROOT, "Python lint"),
        Check(["mypy", str(ROOT / "app" / "src")], ROOT, "Type checks"),
        Check(["pytest", str(ROOT / "app" / "tests")], ROOT, "Unit tests"),
        Check(["terraform", "fmt", "-check"], DEV_ENV, "Terraform formatting"),
        Check(["terraform", "validate"], DEV_ENV, "Terraform validate"),
        Check(["checkov", "-d", str(INFRA_DIR)], ROOT, "Checkov IaC scan"),
        Check(
            [
                "opa",
                "eval",
                "--data",
                str(POLICY_DIR),
                "--input",
                str(plan_json),
                "data.security.allow",
            ],
            ROOT,
            "OPA policy evaluation",
            hint="Review policies in policies/opa if this fails",
            ensure_file=plan_json,
        ),
        Check(
            [
                "trivy",
                "fs",
                "--exit-code",
                "1",
                "--severity",
                "HIGH,CRITICAL",
                str(ROOT / "infra"),
            ],
            ROOT,
            "Trivy filesystem scan",
        ),
    ]


def run_checks(checks: List[Check]) -> List[CheckResult]:
    results: List[CheckResult] = []
    console = Console() if Console else None

    for check in checks:
        if check.ensure_file and not check.ensure_file.exists():
            raise SystemExit(f"Required file missing for {check.name}: {check.ensure_file}")
        if console:
            console.rule(check.description)
            console.print(f"[bold cyan]$ {' '.join(check.command)}[/bold cyan]", highlight=False)
        result = check.run()
        results.append(result)
        if console:
            color = "green" if result.passed else "red"
            console.print(f"[{color}]Return code: {result.returncode} (took {result.duration:.2f}s)[/{color}]\n")
            if result.stdout.strip():
                console.print(Text(result.stdout, style="dim"))
            if result.stderr.strip():
                console.print(Text(result.stderr, style="bright_red"))
        if not result.passed:
            break
    return results


def save_reports(results: List[CheckResult]) -> None:
    REPORT_DIR.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    json_report = REPORT_DIR / f"security-run-{timestamp}.json"
    json_report.write_text(
        json.dumps(
            [
                {
                    "command": r.name,
                    "cwd": str(r.cwd),
                    "returncode": r.returncode,
                    "duration": r.duration,
                    "stdout": r.stdout,
                    "stderr": r.stderr,
                    "hint": r.hint,
                }
                for r in results
            ],
            indent=2,
        ),
        encoding="utf-8",
    )

    md_report = REPORT_DIR / f"security-run-{timestamp}.md"
    with md_report.open("w", encoding="utf-8") as handle:
        handle.write(f"# Security Run Summary ({timestamp})\n\n")
        for res in results:
            status = "✅" if res.passed else "❌"
            handle.write(f"## {status} {res.name}\n")
            handle.write(f"- cwd: `{res.cwd}`\n")
            handle.write(f"- returncode: {res.returncode}\n")
            handle.write(f"- duration: {res.duration:.2f}s\n")
            if res.hint:
                handle.write(f"- hint: {res.hint}\n")
            if res.stdout:
                handle.write("\n<details><summary>stdout</summary>\n\n````\n" + res.stdout + "\n````\n</details>\n")
            if res.stderr:
                handle.write("\n<details><summary>stderr</summary>\n\n````\n" + res.stderr + "\n````\n</details>\n")
        handle.write("\nGenerated at: " + datetime.now().isoformat())

    print(f"JSON report: {json_report}")
    print(f"Markdown report: {md_report}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Run security validation pipeline")
    parser.add_argument("--skip-plan", action="store_true", help="Skip terraform plan generation")
    args = parser.parse_args()

    ensure_dependencies(["ruff", "mypy", "pytest", "terraform", "checkov", "opa", "trivy"])

    with tempfile.TemporaryDirectory() as tmpdir:
        plan_path = Path(tmpdir) / "plan.out"
        plan_json = Path(tmpdir) / "plan.json"

        if not args.skip_plan:
            plan_result = generate_plan(plan_path)
            if plan_result.returncode != 0:
                print(plan_result.stdout)
                print(plan_result.stderr, file=sys.stderr)
                sys.exit(plan_result.returncode)
            show_result = convert_plan_to_json(plan_path, plan_json)
            if show_result.returncode != 0:
                print(show_result.stdout)
                print(show_result.stderr, file=sys.stderr)
                sys.exit(show_result.returncode)
        else:
            plan_json = ROOT / "plan.json"

        checks = build_checks(plan_json)
        results = run_checks(checks)
        save_reports(results)

        if not results[-1].passed:
            sys.exit(results[-1].returncode)


if __name__ == "__main__":
    main()
