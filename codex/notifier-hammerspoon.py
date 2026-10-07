#!/usr/bin/env python3
"""Forward Codex Stop events to Hammerspoon for focus-aware notifications."""

import json
import subprocess
import sys
from urllib.parse import quote, urlencode


def main() -> int:
    try:
        notification = json.load(sys.stdin)
    except json.JSONDecodeError:
        return 1

    message = notification.get('last_assistant_message') or 'No output from Codex'
    # Keep the URL small even when the assistant's final response is very long.
    params = urlencode({'message': message[:2000]}, quote_via=quote)
    return subprocess.run(
        ['/usr/bin/open', '-g', 'hammerspoon://codex-stopped?' + params]
    ).returncode


if __name__ == '__main__':
    sys.exit(main())
