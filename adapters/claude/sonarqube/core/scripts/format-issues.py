#!/usr/bin/env python3
"""
format-issues.py — Formats SonarQube issues as a markdown table

Usage:
    cat issues.json | python3 format-issues.py

Environment variables:
    SONAR_SEVERITY    - Severity filter used (for display)
    SONAR_NEW_CODE    - "true" if new code filter was used
    SONAR_PROJECT_KEY - Project key (for display)
"""

import json
import os
import sys


def get_file_path(component_key, components):
    """Extract file path from component key."""
    comp = components.get(component_key, {})
    return comp.get("path", comp.get("longName", component_key.split(":")[-1]))


def get_file_name(path):
    """Extract filename from path."""
    return path.split("/")[-1]


def main():
    # Read JSON from stdin
    try:
        response = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input - {e}", file=sys.stderr)
        sys.exit(1)

    issues = response.get("issues", [])
    components = {c["key"]: c for c in response.get("components", [])}
    total = response.get("total", len(issues))

    severity_label = os.environ.get("SONAR_SEVERITY", "HIGH,MEDIUM")
    new_code = os.environ.get("SONAR_NEW_CODE", "false") == "true"
    project_key = os.environ.get("SONAR_PROJECT_KEY", "unknown-project")
    scope_label = "new code" if new_code else "overall"

    if not issues:
        print(f"SonarQube: No open {severity_label} impact severity issues found ({scope_label}).")
        sys.exit(0)

    print("<sonar-issues>")
    print(f"SonarQube: {total} open issues ({severity_label} impact, {scope_label}) for {project_key}.")
    print(f"Showing top {len(issues)} sorted by severity.\n")
    print("| # | File | Line | Rule | Message | Impact Severity | Software Quality |")
    print("|---|------|------|------|---------|-----------------|------------------|")

    for i, issue in enumerate(issues, 1):
        path = get_file_path(issue.get("component", ""), components)
        fname = get_file_name(path)
        line = issue.get("line", "?")
        rule = issue.get("rule", "?")
        msg = issue.get("message", "?")

        impacts = issue.get("impacts", [])
        impact_severity = impacts[0]["severity"] if impacts else issue.get("severity", "?")
        software_quality = impacts[0]["softwareQuality"] if impacts else issue.get("type", "?")

        short_msg = (msg[:60] + "...") if len(msg) > 60 else msg
        print(f"| {i} | `{fname}` | {line} | {rule} | {short_msg} | {impact_severity} | {software_quality} |")

    print("\nFix these issues one by one. For each issue:")
    print("1. Read the file at the specified line")
    print("2. Apply the fix following the project coding standards")
    print("3. Move to the next issue")
    print("4. After all fixes, run your build command")
    print("</sonar-issues>")


if __name__ == "__main__":
    main()
