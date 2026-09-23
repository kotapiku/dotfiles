from concurrent.futures import ThreadPoolExecutor
import contextlib
import io
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
import unittest
from unittest.mock import patch

import pdfoutline


class TocTests(unittest.TestCase):
    def test_nested_titles_blank_lines_and_trailing_whitespace(self):
        entries = pdfoutline.toc_to_elist(
            "序章    入門 1  \n    \n    Section 2\n        Detail 3\n    Next 4\nEnd 5\n"
        )
        self.assertEqual([entry.name for entry in entries], ["序章    入門", "End"])
        self.assertEqual([entry.page for entry in entries[0].children], [2, 4])
        self.assertEqual(entries[0].children[0].children[0].name, "Detail")
        pdfoutline.offset_elist(entries, 2)
        self.assertEqual(entries[0].children[0].children[0].page, 5)

    def test_invalid_lines_report_line_number(self):
        for invalid in ("        Skipped 2", "  Bad indent 2", "\tTab 2", "MissingPage",
                        "buzzz9", "Zero 0", "Negative -1"):
            with self.subTest(line=invalid):
                with self.assertRaisesRegex(ValueError, "line 3:"):
                    pdfoutline.toc_to_elist("Intro 1\n\n" + invalid)

    def test_empty_toc_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "empty"):
            pdfoutline.toc_to_elist("\n    \n")

    def test_invalid_offset_does_not_partly_mutate_entries(self):
        entries = pdfoutline.toc_to_elist("First 10\n    Second 1")
        with self.assertRaisesRegex(ValueError, "after offset"):
            pdfoutline.offset_elist(entries, -2)
        self.assertEqual(entries[0].page, 10)
        self.assertEqual(entries[0].children[0].page, 1)

    def test_unicode_and_postscript_characters_are_encoded(self):
        title = "日本語 (title) \\ test"
        marks = pdfoutline.elist_to_gs([pdfoutline.Entry(title, 1)])
        expected = ("\ufeff" + title).encode("utf-16-be").hex().upper()
        self.assertIn(f"/Title <{expected}>", marks)
        self.assertTrue(marks.isascii())


class CommandTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="pdfoutline-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name).resolve()
        self.input = self.root / "input with spaces.pdf"
        self.input.write_bytes(b"fixture for mocked Ghostscript")
        self.toc = self.root / "toc.txt"
        self.toc.write_text("序章 1\n    次節 2\n", encoding="utf-8")
        self.output = self.root / "output.pdf"

    def arguments(self, output=None):
        return [str(self.input), str(self.toc), "0", str(output or self.output)]

    def test_ghostscript_failure_sets_exit_status_and_cleans_temporary_file(self):
        paths = []
        def fail(command, **kwargs):
            paths.append(Path(command[4]))
            self.assertTrue(paths[-1].is_file())
            self.assertTrue(kwargs["check"])
            raise subprocess.CalledProcessError(7, command)

        stderr = io.StringIO()
        with patch("pdfoutline.subprocess.run", side_effect=fail), contextlib.redirect_stderr(stderr):
            with self.assertRaises(SystemExit) as raised:
                pdfoutline.main(self.arguments())
        self.assertEqual(raised.exception.code, 1)
        self.assertIn("Ghostscript exited with status 7", stderr.getvalue())
        self.assertFalse(paths[0].exists())

    def test_concurrent_runs_have_separate_temporary_files(self):
        barrier = threading.Barrier(2)
        paths = []
        def run(command, **kwargs):
            path = Path(command[4])
            paths.append(path)
            barrier.wait(timeout=5)
            self.assertTrue(path.is_file())
            return subprocess.CompletedProcess(command, 0)

        with patch("pdfoutline.subprocess.run", side_effect=run):
            with ThreadPoolExecutor(max_workers=2) as executor:
                results = list(executor.map(pdfoutline.main, [
                    self.arguments(self.root / "one.pdf"), self.arguments(self.root / "two.pdf"),
                ]))
        self.assertEqual(results, [0, 0])
        self.assertNotEqual(paths[0], paths[1])
        self.assertTrue(all(not path.exists() for path in paths))

    def test_reject_input_as_output_before_running_ghostscript(self):
        with patch("pdfoutline.subprocess.run") as run, contextlib.redirect_stderr(io.StringIO()):
            with self.assertRaises(SystemExit):
                pdfoutline.main(self.arguments(self.input))
        run.assert_not_called()
        self.assertEqual(self.input.read_bytes(), b"fixture for mocked Ghostscript")

    @unittest.skipUnless(shutil.which("gs"), "Ghostscript is not installed")
    def test_real_ghostscript_conversion(self):
        subprocess.run(["gs", "-q", "-o", str(self.input), "-sDEVICE=pdfwrite",
                        "-c", "showpage showpage"], check=True, capture_output=True)
        self.assertEqual(pdfoutline.main(self.arguments()), 0)
        self.assertTrue(self.output.read_bytes().startswith(b"%PDF-"))
        subprocess.run(["gs", "-q", "-dBATCH", "-dNOPAUSE", "-sDEVICE=nullpage", str(self.output)],
                       check=True, capture_output=True)


if __name__ == "__main__":
    unittest.main()
