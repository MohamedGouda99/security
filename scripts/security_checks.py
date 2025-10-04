#!/usr/bin/env python3
"""Security automation helper mirroring scripts/security_checks.sh."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_DIR = ROOT / "app"
DEV_INFRA_DIR = ROOT / "infra" / "envs" / "dev"
OPA_POLICY_DIR = ROOT / "policies" / "opa"

COMMANDS = [
    [sys.executable, "-m", "pip", "install", "-e", f"{APP_DIR}[dev]"],
    ["ruff", "check", str(APP_DIR / "src")],
    ["mypy", str(APP_DIR / "src")],
    ["pytest", str(APP_DIR / "tests")],
    ["terraform", "fmt", "-recursive"],
    ["terraform", "init", "-backend=false"],
    ["terraform", "validate"],
    ["checkov", "-d", str(ROOT / "infra")],
    ["opa", "test", str(OPA_POLICY_DIR)],
]

SUMMARY = []


def run(command, cwd=None):
    display = " ".join(command)
    print(f"\n>>> Running: {display}")
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=True)
    SUM_ENTRY = {
        "command": display,
        "cwd": str(cwd) if cwd else str(ROOT),
        "returncode": result.returncode,
        "stdout": result.stdout,
        "stderr": result.stderr,
    }
    SUMMARY.append(SUM_ENTRY)
    sys.stdout.write(result.stdout)
    if result.stderr:
        sys.stderr.write(result.stderr)
    if result.returncode != 0:
        raise SystemExit(json.dumps(SUMMARY, indent=2))


def main():
    run(COMMANDS[0])
    run(COMMANDS[1])
    run(COMMANDS[2])
    run(COMMANDS[3])
    run(COMMANDS[4], cwd=DEV_INFRA_DIR)
    run(COMMANDS[5], cwd=DEV_INFRA_DIR)
    run(COMMANDS[6], cwd=DEV_INFRA_DIR)
    run(COMMANDS[7])
    run(COMMANDS[8])

    print("\nAll security checks completed successfully. Summary:")
    print(json.dumps(SUMMARY, indent=2))


if __name__ == "__main__":
    main()
