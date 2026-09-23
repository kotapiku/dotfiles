"""Add PDF bookmarks from a UTF-8 table of contents using Ghostscript."""

import argparse
from dataclasses import dataclass, field
from pathlib import Path
import re
import subprocess
import tempfile


@dataclass
class Entry:
    name: str
    page: int
    children: list = field(default_factory=list)


def toc_to_elist(toc, TAB="    "):
    """Parse ``title page`` lines; each indentation unit adds one level."""
    if not TAB or not TAB.isspace():
        raise ValueError("indentation must be a nonempty whitespace string")
    entries = []
    levels = [entries]
    for line_number, line in enumerate(toc.splitlines(), start=1):
        if not line.strip():
            continue
        content = line.lstrip(" \t")
        indent = line[:len(line) - len(content)]
        depth, remainder = divmod(len(indent), len(TAB))
        if remainder or indent != TAB * depth:
            raise ValueError(f"line {line_number}: indent with groups of {len(TAB)} spaces")
        if depth >= len(levels):
            raise ValueError(f"line {line_number}: indentation skips a parent level")
        match = re.fullmatch(r"(.+?)\s+([0-9]+)", content.rstrip())
        if not match:
            raise ValueError(f"line {line_number}: expected 'title page' with a numeric page")
        name, page_text = match.groups()
        page = int(page_text)
        if page < 1:
            raise ValueError(f"line {line_number}: page must be at least 1")
        entry = Entry(name.rstrip(), page)
        levels = levels[:depth + 1]
        levels[depth].append(entry)
        levels.append(entry.children)
    if not entries:
        raise ValueError("table of contents is empty")
    return entries


def _walk_entries(elist):
    for entry in elist:
        yield entry
        yield from _walk_entries(entry.children)


def offset_elist(elist, offset):
    """Apply an offset in place after validating all resulting page numbers."""
    entries = list(_walk_entries(elist))
    for entry in entries:
        if entry.page + offset < 1:
            raise ValueError(f"{entry.name!r}: page after offset must be at least 1")
    for entry in entries:
        entry.page += offset


def elist_to_gs(elist):
    def pdfmark_string(value):
        return "<" + ("\ufeff" + value).encode("utf-16-be").hex().upper() + ">"

    return "\n".join(
        f"[/Page {entry.page} /View [/XYZ null null null] "
        f"/Title {pdfmark_string(entry.name)} /Count {len(entry.children)} /OUT pdfmark"
        for entry in _walk_entries(elist)
    )


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inpdf", type=Path)
    parser.add_argument("toc", type=Path, help="UTF-8: title and page, indented by four spaces")
    parser.add_argument("offset", type=int)
    parser.add_argument("outpdf", type=Path)
    args = parser.parse_args(argv)

    try:
        if not args.inpdf.is_file():
            raise ValueError(f"input PDF does not exist: {args.inpdf}")
        if args.inpdf.resolve() == args.outpdf.resolve() or (
            args.outpdf.exists() and args.inpdf.samefile(args.outpdf)
        ):
            raise ValueError("input and output PDF must be different files")
        entries = toc_to_elist(args.toc.read_text(encoding="utf-8"))
        offset_elist(entries, args.offset)
        with tempfile.TemporaryDirectory(prefix="pdfoutline-") as temporary_directory:
            marks = Path(temporary_directory) / "outline.gs"
            marks.write_text(elist_to_gs(entries), encoding="ascii")
            subprocess.run(
                ["gs", "-o", str(args.outpdf.resolve()), "-sDEVICE=pdfwrite",
                 str(marks), "-f", str(args.inpdf.resolve())],
                check=True,
            )
    except subprocess.CalledProcessError as error:
        parser.exit(1, f"pdfoutline: Ghostscript exited with status {error.returncode}\n")
    except (OSError, ValueError) as error:
        parser.exit(1, f"pdfoutline: {error}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
