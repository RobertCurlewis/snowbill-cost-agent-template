#!/usr/bin/env python3
"""Render templated SQL/YAML files under snowflake/ for a target environment.

Supported templates:
- {{ variable_name }}  — replaced with value from config
- {{ include('relative-file.ext') }}  — inlines file content

Usage:
  python scripts/render_snowflake_templates.py --env dev
  python scripts/render_snowflake_templates.py --env prod
  python scripts/render_snowflake_templates.py --env dev --config cookiecutter.yml
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, Set

try:
    import yaml
except ImportError:
    yaml = None  # type: ignore[assignment]


# Match an include on its own line, capturing any leading indentation so the
# included (possibly multi-line) content can be re-indented to that level —
# essential when the include sits inside a YAML block scalar.
INCLUDE_RE = re.compile(
    r"(?m)^([ \t]*)\{\{\s*include\(\s*['\"]([^'\"]+)['\"]\s*\)\s*\}\}[ \t]*$"
)
VAR_RE = re.compile(r"{{\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*}}")


# Default environment contexts — override by providing a cookiecutter.yml
DEFAULT_ENV_CONTEXT = {
    "dev": {
        "database": "DEV_DB",
        "schema": "MY_SCHEMA",
        "warehouse": "MY_WH",
        "agent_name": "MY_AGENT",
        "agent_description": "My Cortex Agent",
    },
    "prod": {
        "database": "PROD_DB",
        "schema": "MY_SCHEMA",
        "warehouse": "MY_WH",
        "agent_name": "MY_AGENT",
        "agent_description": "My Cortex Agent",
    },
}


def _load_config(config_path: Path | None) -> dict:
    """Load cookiecutter.yml and derive env contexts from it."""
    if config_path is None or not config_path.exists():
        return DEFAULT_ENV_CONTEXT

    if yaml is None:
        print("WARNING: PyYAML not installed. Using default config.")
        return DEFAULT_ENV_CONTEXT

    with open(config_path) as f:
        config = yaml.safe_load(f) or {}

    return {
        "dev": {
            "database": config.get("snowflake_database_dev", "DEV_DB"),
            "schema": config.get("snowflake_schema", "MY_SCHEMA"),
            "warehouse": config.get("snowflake_warehouse", "MY_WH"),
            "warehouse_cicd": config.get("snowflake_warehouse_cicd", "MY_CICD_WH"),
            "agent_name": config.get("agent_name", "MY_AGENT").upper().replace(" ", "_"),
            "agent_description": config.get("agent_description", "My Cortex Agent"),
            "currency": config.get("agent_currency", "USD"),
            "credit_rate": str(config.get("agent_credit_rate", "ASK")),
        },
        "prod": {
            "database": config.get("snowflake_database_prod", "PROD_DB"),
            "schema": config.get("snowflake_schema", "MY_SCHEMA"),
            "warehouse": config.get("snowflake_warehouse", "MY_WH"),
            "warehouse_cicd": config.get("snowflake_warehouse_cicd", "MY_CICD_WH"),
            "agent_name": config.get("agent_name", "MY_AGENT").upper().replace(" ", "_"),
            "agent_description": config.get("agent_description", "My Cortex Agent"),
            "currency": config.get("agent_currency", "USD"),
            "credit_rate": str(config.get("agent_credit_rate", "ASK")),
        },
    }


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Render templated Snowflake SQL/YAML files."
    )
    parser.add_argument("--env", choices=["dev", "prod"], default="dev")
    parser.add_argument(
        "--config",
        default="cookiecutter.yml",
        help="Path to cookiecutter.yml config file.",
    )
    parser.add_argument(
        "--input-dir",
        default="snowflake",
        help="Root folder containing templated SQL files.",
    )
    parser.add_argument(
        "--output-dir",
        default="snowflake/rendered",
        help="Root output folder where rendered SQL is written.",
    )

    # Support positional env=dev syntax for convenience
    normalized_argv: list[str] = []
    for arg in argv:
        if arg.startswith("env="):
            normalized_argv.extend(["--env", arg.split("=", 1)[1]])
        else:
            normalized_argv.append(arg)

    return parser.parse_args(normalized_argv)


def _build_context(env: str, env_contexts: dict) -> Dict[str, str]:
    context = dict(env_contexts.get(env, {}))
    context["env"] = env
    return {k: str(v) for k, v in context.items()}


def _render_text(
    text: str,
    source_dir: Path,
    context: Dict[str, str],
    include_stack: Set[Path],
) -> str:
    def include_replacer(match: re.Match[str]) -> str:
        indent = match.group(1)
        include_name = match.group(2)
        include_path = (source_dir / include_name).resolve()

        if include_path in include_stack:
            raise ValueError(f"Circular include detected: {include_path}")
        if not include_path.exists():
            raise FileNotFoundError(f"Include file not found: {include_path}")

        include_stack.add(include_path)
        included_text = include_path.read_text(encoding="utf-8")
        rendered = _render_text(
            included_text, include_path.parent, context, include_stack
        )
        include_stack.remove(include_path)

        # Re-indent every non-empty line to the include's indentation level, so
        # multi-line content stays valid inside a YAML block scalar.
        lines = rendered.split("\n")
        return "\n".join(indent + line if line.strip() else line for line in lines)

    def var_replacer(match: re.Match[str]) -> str:
        variable_name = match.group(1)
        if variable_name not in context:
            raise KeyError(f"Template variable not found: {variable_name}")
        return context[variable_name]

    text = INCLUDE_RE.sub(include_replacer, text)
    text = VAR_RE.sub(var_replacer, text)
    return text


def _render_file(source_file: Path, output_file: Path, context: Dict[str, str]) -> None:
    template_text = source_file.read_text(encoding="utf-8")
    rendered_text = _render_text(
        template_text,
        source_file.parent,
        context,
        include_stack={source_file.resolve()},
    )

    output_file.parent.mkdir(parents=True, exist_ok=True)
    output_file.write_text(rendered_text, encoding="utf-8")


def main(argv: list[str]) -> int:
    args = _parse_args(argv)
    env = args.env

    print(f"Environment: {env}")

    config_path = Path(args.config)
    env_contexts = _load_config(config_path)
    context = _build_context(env, env_contexts)

    print(f"Database: {context.get('database', 'NOT SET')}")
    print(f"Schema: {context.get('schema', 'NOT SET')}")

    input_root = Path(args.input_dir)
    output_root = Path(args.output_dir) / env

    if not input_root.exists():
        raise FileNotFoundError(f"Input directory not found: {input_root}")

    sql_files = [
        path
        for path in input_root.rglob("*.sql")
        if output_root not in path.parents and "rendered" not in path.parts
    ]
    yaml_files = [
        path
        for path in input_root.rglob("*.yaml")
        if output_root not in path.parents and "rendered" not in path.parts
    ]
    yml_files = [
        path
        for path in input_root.rglob("*.yml")
        if output_root not in path.parents and "rendered" not in path.parts
    ]
    template_files = sql_files + yaml_files + yml_files

    if not template_files:
        print(f"No SQL/YAML templates found under {input_root}")
        return 0

    rendered_count = 0
    for source_file in sorted(template_files):
        relative_path = source_file.relative_to(input_root)
        output_file = output_root / relative_path
        _render_file(source_file, output_file, context)
        print(f"  Rendered: {source_file} -> {output_file}")
        rendered_count += 1

    print(f"\nRendered {rendered_count} template(s) into {output_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
