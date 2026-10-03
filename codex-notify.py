#!/usr/bin/env python3
"""Silent, click-to-dismiss Codex notifications using lifecycle hooks.

Run with --hook and a lifecycle event on stdin. The detached --deliver worker
waits for actual turn completion and deduplicates delivery. Use the macOS
Alerts notification style to keep notifications visible until dismissed.
The old notify-command arguments only forward to the previous completion hook.
"""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sqlite3
import subprocess
import sys
import time
import uuid

COMPLETION_WAIT_SECONDS = 30


def run(command):
    try:
        return subprocess.run(
            command, check=False, timeout=10, stdout=subprocess.DEVNULL,
        ).returncode
    except (OSError, subprocess.TimeoutExpired) as error:
        print(f"codex-notify: {type(error).__name__}", file=sys.stderr)
        return 1


def notification_kind(event):
    hook = event.get("hook_event_name")
    tool = event.get("tool_name", "")
    if hook == "Stop":
        return "complete", "応答完了", "応答が完了しました。"
    if hook == "PermissionRequest" or (
        hook == "PreToolUse" and re.search(r"(^|[._:])request_permissions$", tool)
    ):
        return "approval", "承認が必要です", "操作の承認・確認を待っています。"
    if hook == "PreToolUse" and re.search(r"(^|[._:])request_user_input(_async)?$", tool):
        return "question", "回答が必要です", "質問への回答を待っています。"
    # Legacy agent-turn-complete events must not generate notifications.
    return None


def completion_status(event):
    """Check the local CLI transcript; Stop alone can still precede continuation.

    Codex 0.158 writes task_complete after all Stop hooks finish. Checking in a
    detached worker avoids blocking that record. Unknown formats fail closed.
    """
    turn = event.get("turn_id")
    transcript = event.get("transcript_path")
    if not turn or not transcript:
        return "obsolete"
    try:
        with Path(transcript).open("rb") as stream:
            meta = json.loads(stream.readline()).get("payload", {})
            source = meta.get("source")
            if isinstance(source, dict) and any(k in source for k in ("subagent", "subAgent")):
                return "obsolete"
            if meta.get("id") != event.get("session_id"):
                return "obsolete"
            stream.seek(0, os.SEEK_END)
            offset = max(0, stream.tell() - 1024 * 1024)
            stream.seek(offset)
            if offset:
                stream.readline()
            lines = stream.read().splitlines()
    except (OSError, ValueError):
        return "pending"

    latest_turn = None
    status = "pending"
    for line in lines:
        try:
            record = json.loads(line)
        except ValueError:
            continue
        if record.get("type") != "event_msg":
            continue
        payload = record.get("payload", {})
        if payload.get("type") in ("task_started", "task_complete"):
            latest_turn = payload.get("turn_id")
            status = "complete" if payload["type"] == "task_complete" else "pending"
        elif payload.get("type") in ("turn_aborted", "task_failed"):
            status = "obsolete"
    if latest_turn and latest_turn != turn:
        return "obsolete"
    return status


def notification_key(event, kind):
    session, turn = event.get("session_id"), event.get("turn_id")
    if not session or not turn:
        return None
    request = None if kind == "complete" else (
        event.get("tool_use_id") or [event.get("tool_name"), event.get("tool_input")]
    )
    value = json.dumps([session, turn, kind, request], sort_keys=True, ensure_ascii=False)
    return hashlib.sha256(value.encode()).hexdigest()


def state_connection():
    cache = Path(os.environ.get(
        "CODEX_NOTIFY_CACHE_DIR", str(Path.home() / "Library/Caches/codex-notify"),
    ))
    cache.mkdir(mode=0o700, parents=True, exist_ok=True)
    connection = sqlite3.connect(cache / "sent.sqlite3", timeout=5)
    connection.execute("CREATE TABLE IF NOT EXISTS sent (key TEXT PRIMARY KEY, at REAL NOT NULL)")
    return connection


def claim_notification(key):
    connection = state_connection()
    try:
        with connection:
            connection.execute("DELETE FROM sent WHERE at < ?", (time.time() - 7 * 86400,))
            return connection.execute(
                "INSERT OR IGNORE INTO sent VALUES (?, ?)", (key, time.time()),
            ).rowcount == 1
    finally:
        connection.close()


def release_notification(key):
    connection = state_connection()
    try:
        with connection:
            connection.execute("DELETE FROM sent WHERE key = ?", (key,))
    finally:
        connection.close()


def find_notifier():
    return shutil.which("terminal-notifier") or next((
        path for path in ("/opt/homebrew/bin/terminal-notifier", "/usr/local/bin/terminal-notifier")
        if os.access(path, os.X_OK)
    ), None)


def deliver(event):
    notification = notification_kind(event)
    if notification is None:
        return 0
    kind, title, action = notification
    key = notification_key(event, kind)
    if key is None:
        return 0
    if kind == "complete":
        deadline = time.monotonic() + COMPLETION_WAIT_SECONDS
        while True:
            status = completion_status(event)
            if status == "complete":
                break
            if status == "obsolete" or time.monotonic() >= deadline:
                return 0
            time.sleep(0.25)

    notifier = find_notifier()
    if not notifier or not claim_notification(key):
        return 0
    project = Path(event.get("cwd") or ".").name
    # Keep independent notifications from replacing one another.
    group = "codex-" + uuid.uuid4().hex
    command = [
        notifier, "-title", "Codex — " + title,
        "-message", f"{project}: {action}" if project else action,
        "-group", group,
    ]
    focus_url = os.environ.get("WARP_FOCUS_URL", "")
    valid_focus_url = re.fullmatch(r"warp://session/[0-9a-fA-F-]{32,36}", focus_url)
    if valid_focus_url or os.environ.get("TERM_PROGRAM") == "WarpTerminal":
        # Warp can reject a stale session link without bringing its window
        # forward. Activate the app independently before opening the link.
        command += ["-activate", "dev.warp.Warp-Stable"]
    if valid_focus_url:
        command += ["-open", focus_url]
    # Omitting -sound keeps terminal-notifier silent.
    if run(command):
        release_notification(key)
        return 1
    # terminal-notifier removes the notification when it is clicked, then
    # opens the Warp session if supplied. No timed cleanup is needed.
    return 0


def start_delivery(event):
    if notification_kind(event) is None:
        return
    worker = subprocess.Popen(
        [sys.executable, str(Path(__file__).resolve()), "--deliver"],
        stdin=subprocess.PIPE, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        start_new_session=True,
    )
    try:
        worker.stdin.write(json.dumps(event).encode())
    finally:
        worker.stdin.close()


def main():
    if sys.argv[1:] in (["--hook"], ["--deliver"]):
        event = {}
        try:
            event = json.load(sys.stdin)
            if not isinstance(event, dict):
                return 0
            if sys.argv[1] == "--deliver":
                return deliver(event)
            start_delivery(event)
        except (OSError, ValueError, TypeError, AttributeError, sqlite3.Error) as error:
            print(f"codex-notify: {type(error).__name__}", file=sys.stderr)
        finally:
            if sys.argv[1] == "--hook" and isinstance(event, dict) and event.get("hook_event_name") == "Stop":
                print("{}")
        return 0

    # Running sessions may still use the previous notify array. Preserve the
    # Computer Use callback, but never notify on that old event stream.
    if len(sys.argv) > 2:
        run([*sys.argv[1:-1], sys.argv[-1]])
    return 0


if __name__ == "__main__":
    sys.exit(main())
