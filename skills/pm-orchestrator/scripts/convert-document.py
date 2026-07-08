#!/usr/bin/env python
"""
Convert user-provided documents to Markdown with markitdown.

用途：把用户提供的 PDF、Word、PPT、Excel、HTML、CSV、TXT 等文件转换成
Markdown，供需求分析阶段作为 file-extract 来源继续做事实抽取和校验。

This script is intentionally small and deterministic: it does not download
dependencies, does not call external services, and does not write project
memory files. The requirement-analysis agent can use the generated Markdown as
a file-extract source, then apply the data validation rules from its references.

边界：本脚本只负责“文档转 Markdown + 可选 metadata 输出”，不判断事实是否
可信，也不写入 facts.json、refs.json 等项目记忆文件。
"""

from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


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
        "--title",
        help="Optional source title to include in metadata.",
    )
    return parser


def load_markitdown() -> Any:
    # 延迟导入，方便在未安装 markitdown 时给出清晰的依赖安装提示。
    try:
        from markitdown import MarkItDown
    except ImportError as exc:
        raise RuntimeError(
            "Python package 'markitdown' is not installed. Install it with: "
            "python -m pip install markitdown"
        ) from exc
    return MarkItDown


def extract_text(result: Any) -> str:
    # 兼容 markitdown 不同版本可能返回的字段名，避免脚本绑死单一版本。
    for attr in ("text_content", "markdown", "content"):
        value = getattr(result, attr, None)
        if isinstance(value, str):
            return value
    if isinstance(result, str):
        return result
    raise TypeError("markitdown returned an unsupported result shape.")


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def build_metadata(source: Path, markdown: str, title: str | None) -> dict[str, Any]:
    # metadata 用于后续溯源：写入 facts.json 前仍需用户确认和数据校验。
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

    try:
        MarkItDown = load_markitdown()
        converter = MarkItDown()
        result = converter.convert(str(source))
        markdown = extract_text(result)
    except Exception as exc:
        print(f"Document conversion failed: {exc}", file=sys.stderr)
        return 1

    if args.output:
        write_text(Path(args.output).expanduser().resolve(), markdown)
    else:
        sys.stdout.write(markdown)
        if markdown and not markdown.endswith("\n"):
            sys.stdout.write("\n")

    if args.metadata_output:
        # metadata 与 Markdown 分开输出，便于 agent 单独引用来源信息。
        metadata = build_metadata(source, markdown, args.title)
        metadata_path = Path(args.metadata_output).expanduser().resolve()
        write_text(metadata_path, json.dumps(metadata, ensure_ascii=False, indent=2))

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
