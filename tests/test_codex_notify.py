from concurrent.futures import ThreadPoolExecutor
import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("codex_notify", Path(__file__).resolve().parents[1] / "codex-notify.py")
notify = importlib.util.module_from_spec(spec)
spec.loader.exec_module(notify)


class NotificationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.transcript = self.root / "rollout.jsonl"
        self.transcript.write_text(json.dumps({
            "type": "session_meta", "payload": {"id": "session", "source": "cli"},
        }) + "\n")
        self.event = {
            "hook_event_name": "Stop", "session_id": "session", "turn_id": "turn",
            "transcript_path": str(self.transcript), "cwd": "/project",
        }
        self.environment = patch.dict(os.environ, {
            "CODEX_NOTIFY_CACHE_DIR": str(self.root / "cache"),
            "WARP_FOCUS_URL": "warp://session/" + "a" * 32,
            "TERM_PROGRAM": "WarpTerminal",
        })
        self.environment.start()
        self.addCleanup(self.environment.stop)

    def append(self, kind, turn="turn"):
        with self.transcript.open("a") as stream:
            stream.write(json.dumps({
                "type": "event_msg", "payload": {"type": kind, "turn_id": turn},
            }) + "\n")

    def test_intermediate_and_legacy_events_do_not_notify(self):
        self.append("task_started")
        with self.transcript.open("a") as stream:
            stream.write(json.dumps({"type": "event_msg", "payload": {
                "type": "item_completed", "turn_id": "turn",
                "item": {"type": "AgentMessage", "phase": "commentary"},
            }}) + "\n")
        with patch.object(notify, "COMPLETION_WAIT_SECONDS", 0), patch.object(notify, "run") as run:
            notify.deliver(self.event)
            notify.deliver({"type": "agent-turn-complete", "thread-id": "session", "turn-id": "turn"})
        run.assert_not_called()

    def test_concurrent_duplicates_send_once_without_timed_removal(self):
        self.append("task_started")
        self.append("task_complete")
        with patch.object(notify, "find_notifier", return_value="notifier"), \
             patch.object(notify.time, "sleep") as sleep, \
             patch.object(notify, "run", return_value=0) as run:
            with ThreadPoolExecutor(max_workers=6) as pool:
                list(pool.map(notify.deliver, [self.event] * 6))
        run.assert_called_once()
        sleep.assert_not_called()
        sent = run.call_args.args[0]
        self.assertNotIn("-sound", sent)
        self.assertEqual(sent[sent.index("-activate") + 1], "dev.warp.Warp-Stable")
        self.assertEqual(sent[sent.index("-open") + 1], os.environ["WARP_FOCUS_URL"])

    def test_warp_is_activated_even_without_a_usable_session_link(self):
        event = dict(self.event, hook_event_name="PermissionRequest")
        for focus_url in ("", "warp://session/invalid", "https://example.com"):
            with self.subTest(focus_url=focus_url), \
                 patch.dict(os.environ, {"WARP_FOCUS_URL": focus_url}), \
                 patch.object(notify, "find_notifier", return_value="notifier"), \
                 patch.object(notify, "run", return_value=0) as run:
                notify.deliver(dict(event, tool_use_id=focus_url))
            sent = run.call_args.args[0]
            self.assertEqual(sent[sent.index("-activate") + 1], "dev.warp.Warp-Stable")
            self.assertNotIn("-open", sent)

    def test_other_terminals_do_not_activate_warp(self):
        event = dict(self.event, hook_event_name="PermissionRequest")
        with patch.dict(os.environ, {"WARP_FOCUS_URL": "", "TERM_PROGRAM": "Apple_Terminal"}), \
             patch.object(notify, "find_notifier", return_value="notifier"), \
             patch.object(notify, "run", return_value=0) as run:
            notify.deliver(event)
        self.assertNotIn("-activate", run.call_args.args[0])
        self.assertNotIn("-open", run.call_args.args[0])

    def test_new_turn_suppresses_stale_completion(self):
        self.append("task_complete")
        self.append("task_started", "next-turn")
        with patch.object(notify, "run") as run:
            notify.deliver(self.event)
        run.assert_not_called()

    def test_waits_until_completion_is_recorded(self):
        self.append("task_started")
        def finish(_):
            self.append("task_complete")
        with patch.object(notify.time, "sleep", side_effect=finish), \
             patch.object(notify, "find_notifier", return_value="notifier"), \
             patch.object(notify, "run", return_value=0) as run:
            notify.deliver(self.event)
        run.assert_called_once()

    def test_approval_and_question_remain_independent(self):
        approval = dict(self.event, hook_event_name="PermissionRequest", tool_name="Bash", tool_input={"command": "build"})
        question = dict(self.event, hook_event_name="PreToolUse", tool_name="functions.request_user_input_async", tool_use_id="question")
        with patch.object(notify, "find_notifier", return_value="notifier"), \
             patch.object(notify, "run", return_value=0) as run:
            notify.deliver(approval)
            notify.deliver(question)
        commands = [call.args[0] for call in run.call_args_list]
        self.assertEqual(len(commands), 2)
        self.assertIn("Codex — 承認が必要です", commands[0])
        self.assertIn("Codex — 回答が必要です", commands[1])
        groups = [command[command.index("-group") + 1] for command in commands]
        self.assertNotEqual(*groups)


if __name__ == "__main__":
    unittest.main()
