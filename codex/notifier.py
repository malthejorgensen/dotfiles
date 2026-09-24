#!/usr/bin/env -S uv run --script
import platform
import subprocess
import json
import sys

"""
Raise a desktop notification with sound when Codex is finished and
waiting for user input.
"""


def main() -> int:

    # Only works on macOS
    assert platform.system() == "Darwin"

    try:
        notification = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 1

    with open("/Users/malthejorgensen/.codex/notification-log-malthe.log", "a") as f:
        notification_json = json.dumps(notification, indent=4)
        f.write("\n\n" + notification_json)

    notification_title = "Codex: Waiting for input"
    notification_content = notification.get("last_assistant_message") or "No output from Codex"
    subprocess.run(
        [
            "osascript",
            "-e",
            'on run argv\n'
            'display notification (item 1 of argv) with title (item 2 of argv) sound name "Glass"\n'
            'end run',
            notification_content,
            notification_title,
        ]
    )

    return 0


if __name__ == "__main__":
    sys.exit(main())
