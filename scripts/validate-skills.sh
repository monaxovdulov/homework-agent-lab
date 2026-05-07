#!/usr/bin/env bash
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT"

python3 - <<'PY'
from pathlib import Path
import sys

try:
    import yaml
except Exception as exc:
    raise SystemExit(f"Missing PyYAML: {exc}")

failed = False

for path in sorted(Path(".agents/skills").glob("*/SKILL.md")):
    item_failed = False
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        print(f"FAIL {path}: missing YAML frontmatter")
        failed = True
        item_failed = True
        continue

    end = text.find("\n---\n", 4)
    if end == -1:
        print(f"FAIL {path}: unterminated YAML frontmatter")
        failed = True
        item_failed = True
        continue

    raw = text[4:end]
    try:
        data = yaml.safe_load(raw)
    except Exception as exc:
        print(f"FAIL {path}: invalid YAML: {exc}")
        failed = True
        item_failed = True
        continue

    if not isinstance(data, dict):
        print(f"FAIL {path}: frontmatter must be a mapping")
        failed = True
        item_failed = True
        continue

    for key in ("name", "description"):
        if not data.get(key):
            print(f"FAIL {path}: missing required key: {key}")
            failed = True
            item_failed = True

    if not item_failed:
        print(f"OK {path}")

if failed:
    sys.exit(1)
PY
