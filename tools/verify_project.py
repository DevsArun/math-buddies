#!/usr/bin/env python3
"""Math Buddies local verification gate.
Checks: YAML parse, brace/paren balance for Dart/Kotlin/KTS, XML parse,
pubspec version format. Exit 1 on any failure. Run: python3 tools/verify_project.py
"""
import os
import re
import sys
import xml.etree.ElementTree as ET

import yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAILURES = []


def fail(msg):
    FAILURES.append(msg)
    print("FAIL:", msg)


def check_yaml(path):
    full = os.path.join(ROOT, path)
    try:
        with open(full, "r", encoding="utf-8") as f:
            yaml.safe_load(f)
        print("OK yaml:", path)
    except Exception as e:  # noqa: BLE001
        fail(f"YAML parse error in {path}: {e}")


def strip_comments_and_strings(text):
    """Remove // and /* */ comments and single/double quoted strings."""
    out = []
    i, n = 0, len(text)
    mode = None  # None | 'line' | 'block' | 'sq' | 'dq'
    while i < n:
        c = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if mode is None:
            if c == "/" and nxt == "/":
                mode = "line"; i += 2; continue
            if c == "/" and nxt == "*":
                mode = "block"; i += 2; continue
            if c == "'":
                mode = "sq"; i += 1; continue
            if c == '"':
                mode = "dq"; i += 1; continue
            out.append(c); i += 1; continue
        if mode == "line":
            if c == "\n":
                mode = None; out.append(c)
            i += 1; continue
        if mode == "block":
            if c == "*" and nxt == "/":
                mode = None; i += 2; continue
            i += 1; continue
        # inside string
        if c == "\\":
            i += 2; continue
        if (mode == "sq" and c == "'") or (mode == "dq" and c == '"'):
            mode = None
        i += 1
    return "".join(out)


def check_balance(path):
    full = os.path.join(ROOT, path)
    with open(full, "r", encoding="utf-8") as f:
        text = strip_comments_and_strings(f.read())
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for ch in text:
        if ch in "([{":
            stack.append(ch)
        elif ch in ")]}":
            if not stack or stack[-1] != pairs[ch]:
                fail(f"Unbalanced '{ch}' in {path}")
                return
            stack.pop()
    if stack:
        fail(f"Unclosed '{stack[-1]}' in {path}")
    else:
        print("OK balance:", path)


def check_xml(path):
    full = os.path.join(ROOT, path)
    try:
        ET.parse(full)
        print("OK xml:", path)
    except Exception as e:  # noqa: BLE001
        fail(f"XML parse error in {path}: {e}")


def main():
    check_yaml("pubspec.yaml")
    check_yaml("analysis_options.yaml")
    check_yaml(".github/workflows/build.yml")

    with open(os.path.join(ROOT, "pubspec.yaml"), "r", encoding="utf-8") as f:
        pub = yaml.safe_load(f)
    version = str(pub.get("version", ""))
    if not re.match(r"^\d+\.\d+\.\d+\+\d+$", version):
        fail(f"pubspec version '{version}' must be X.Y.Z+N (rule J12)")
    else:
        print("OK version:", version)

    for dirpath, _dirnames, filenames in os.walk(ROOT):
        for fn in filenames:
            rel = os.path.relpath(os.path.join(dirpath, fn), ROOT)
            if fn.endswith((".dart", ".kt", ".kts")):
                check_balance(rel)
            if fn.endswith(".xml"):
                check_xml(rel)

    if FAILURES:
        print(f"\n{len(FAILURES)} CHECK(S) FAILED")
        sys.exit(1)
    print("\nALL CHECKS PASSED ✅")


if __name__ == "__main__":
    main()
