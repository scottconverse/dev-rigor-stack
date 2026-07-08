#!/usr/bin/env python3
"""Verify <!-- sync:NAME --> blocks stay identical between a SKILL.md and its
SKILL-LITE.md. Run by CI; exits 1 with a diff summary on any drift.

Usage: python3 tools/check_sync.py [skill_dir ...]
Defaults to every skills/*/ directory that has both files.
"""
import re
import sys
from pathlib import Path

BLOCK = re.compile(r"<!--\s*sync:([\w-]+)((?:\s+[\w-]+:[\w-]+)*)\s*-->\n(.*?)<!--\s*/sync:\1\s*-->", re.S)


def blocks(path: Path) -> dict:
    """name -> (attrs dict, body). The full SKILL.md marks each block lite:required
    (must exist verbatim in SKILL-LITE.md) or lite:excluded (must NOT appear there)."""
    out = {}
    for name, attrstr, body in BLOCK.findall(path.read_text(encoding="utf-8")):
        attrs = dict(a.split(":", 1) for a in attrstr.split())
        out[name] = (attrs, body)
    return out


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    dirs = [Path(a) for a in sys.argv[1:]] or sorted((repo / "skills").iterdir())
    failed = False
    checked = 0
    for d in dirs:
        full, lite = d / "SKILL.md", d / "SKILL-LITE.md"
        if not (full.exists() and lite.exists()):
            continue
        fb, lb = blocks(full), blocks(lite)
        checked += 1
        for name, (attrs, body) in fb.items():
            mode = attrs.get("lite", "required")
            if mode == "excluded":
                if name in lb:
                    print(f"FAIL {d.name}: sync block '{name}' is lite:excluded but present in SKILL-LITE.md")
                    failed = True
            elif name not in lb:
                print(f"FAIL {d.name}: sync block '{name}' missing from SKILL-LITE.md")
                failed = True
            elif lb[name][1] != body:
                print(f"FAIL {d.name}: sync block '{name}' differs between SKILL.md and SKILL-LITE.md")
                failed = True
        for name in lb:
            if name not in fb:
                print(f"FAIL {d.name}: sync block '{name}' exists only in SKILL-LITE.md")
                failed = True
    if not checked:
        print("FAIL no skill directory with both SKILL.md and SKILL-LITE.md found")
        return 1
    if failed:
        return 1
    print(f"ok   sync blocks identical across {checked} skill(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
