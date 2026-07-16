#!/usr/bin/env python
"""
Convert user-provided documents to Markdown with markitdown.

This script is intentionally small and deterministic: it does not download
dependencies, does not call external services, and does not write project
memory files. The extracted Markdown is still untrusted input and must be
validated by the relevant agent before it becomes project facts.
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

DEFAULT_MAX_BYTES = 50 * 1024 * 1024


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Convert PDF/Office/HTML/text documents to Markdown using markitdown.",
    )
    parser.add_argument(
        "input",
        help="Path to the source document, for example a PDF, DOCX, PPTX, XLSX, HTML, CSV, or TXT file.",
    )
    parser.add_argument(
        "-o",
        "--output",
        help="Path to write the Markdown output. If omitted, Markdown is written to stdout.",
    )
    parser.add_argument(
        "--metadata-output",
        help="Optional path to write extraction metadata as JSON.",
    )
    parser.add_argument(
        "--output-root",
        help="Directory that output files must stay inside. Defaults to the current working directory.",
    )
    parser.add_argument(
        "--max-bytes",
        type=int,
        default=DEFAULT_MAX_BYTES,
        help="Maximum accepted input size in bytes. Defaults to 50 MiB.",
    )
    parser.add_argument(
        "--title",
        help="Optional source title to include in metadata.",
    )
    return parser


def load_markitdown() -> Any:
    try:
        from markitdown import MarkItDown
    except ImportError as exc:
        raise RuntimeError(
            "Python package 'markitdown' is not installed. Install it with: "
            "python -m pip install markitdown"
        ) from exc
    return MarkItDown


def extract_text(result: Any) -> str:
    for attr in ("text_content", "markdown", "content"):
        value = getattr(result, attr, None)
        if isinstance(value, str):
            return value
    if isinstance(result, str):
        return result
    raise TypeError("markitdown returned an unsupported result shape.")


def resolve_output_path(path_arg: str, output_root: Path) -> Path:
    output_path = Path(path_arg).expanduser().resolve()
    root = output_root.expanduser().resolve()
    try:
        output_path.relative_to(root)
    except ValueError as exc:
        raise ValueError(f"Output path must be inside output root: {root}") from exc
    return output_path


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def build_metadata(source: Path, markdown: str, title: str | None) -> dict[str, Any]:
    stat = source.stat()
    return {
        "sourceType": "file-extract",
        "converter": "markitdown",
        "sourcePath": str(source),
        "sourceTitle": title or source.stem,
        "sourceSuffix": source.suffix.lower(),
        "sourceSizeBytes": stat.st_size,
        "sourceModifiedAt": datetime.fromtimestamp(stat.st_mtime, timezone.utc).isoformat(),
        "extractedAt": datetime.now(timezone.utc).isoformat(),
        "markdownCharCount": len(markdown),
        "markdownLineCount": markdown.count("\n") + (1 if markdown else 0),
    }


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    source = Path(args.input).expanduser().resolve()
    if not source.exists():
        print(f"Input file does not exist: {source}", file=sys.stderr)
        return 2
    if not source.is_file():
        print(f"Input path is not a file: {source}", file=sys.stderr)
        return 2

    if args.max_bytes <= 0:
        print("--max-bytes must be greater than 0", file=sys.stderr)
        return 2
    if source.stat().st_size > args.max_bytes:
        print(f"Input file is larger than --max-bytes ({args.max_bytes}): {source}", file=sys.stderr)
        return 2

    output_root = Path(args.output_root).expanduser().resolve() if args.output_root else Path.cwd().resolve()

    try:
        MarkItDown = load_markitdown()
        converter = MarkItDown()
        result = converter.convert(str(source))
        markdown = extract_text(result)
    except Exception as exc:
        print(f"Document conversion failed: {exc}", file=sys.stderr)
        return 1

    try:
        if args.output:
            output_path = resolve_output_path(args.output, output_root)
            write_text(output_path, markdown)
        else:
            sys.stdout.write(markdown)
            if markdown and not markdown.endswith("\n"):
                sys.stdout.write("\n")

        if args.metadata_output:
            metadata = build_metadata(source, markdown, args.title)
            metadata_path = resolve_output_path(args.metadata_output, output_root)
            write_text(metadata_path, json.dumps(metadata, ensure_ascii=False, indent=2))
    except Exception as exc:
        print(f"Document output failed: {exc}", file=sys.stderr)
        return 2

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
