#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
import random
import shutil
import string
import subprocess
import sys
from pathlib import Path

"""
SPEC:

`wk` is an executable `uv` script with hashbang line and all that:

- creates a git worktree in `<git_repo_root>/.worktrees/<6 char lowercase alphanum>/`
"""


def cmd_delete():
    # Find the common git dir — works from both main worktree and linked worktrees
    result = subprocess.run(
        ["git", "rev-parse", "--git-common-dir"], capture_output=True, text=True
    )
    if result.returncode != 0:
        print("error: not inside a git repository", file=sys.stderr)
        sys.exit(1)

    git_common_dir = Path(result.stdout.strip())
    if not git_common_dir.is_absolute():
        git_common_dir = Path.cwd() / git_common_dir
    main_repo_root = git_common_dir.parent

    subprocess.run(["git", "worktree", "remove", str(Path.cwd())], check=True)
    print(main_repo_root)


def main():
    args = sys.argv[1:]

    if args and args[0] == "delete":
        cmd_delete()
        return

    # Find git repo root
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    if result.returncode != 0:
        print("error: not inside a git repository", file=sys.stderr)
        sys.exit(1)

    repo_root = Path(result.stdout.strip())

    # Generate 6-char random lowercase alphanumeric name
    chars = string.ascii_lowercase + string.digits
    name = "".join(random.choices(chars, k=6))

    worktree_path = repo_root / ".worktrees" / name
    worktree_path.parent.mkdir(exist_ok=True)

    copy_claude = "--claude" in args
    if copy_claude:
        args.remove("--claude")

    branch = args[0] if args else None
    if branch:
        branch_exists = subprocess.run(
            ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
            capture_output=True,
        ).returncode == 0
        if branch_exists:
            cmd = ["git", "worktree", "add", str(worktree_path), branch]
        else:
            cmd = ["git", "worktree", "add", "-b", branch, str(worktree_path)]
    else:
        cmd = ["git", "worktree", "add", "--detach", str(worktree_path)]
        print(
            "Due to how `git worktree` works you are in a detached HEAD state."
            "Run `git checkout -b <branch_name>` to get a branch :)"
        )
    subprocess.run(cmd, check=True)

    if copy_claude:
        claude_dir = Path.home() / ".claude" / "projects"
        cwd = Path.cwd()
        src = claude_dir / cwd.as_posix().replace("/", "-")
        dst = claude_dir / worktree_path.as_posix().replace("/", "-")
        if src.exists():
            shutil.copytree(src, dst)
            # Replace
            for f in dst.rglob("*"):
                if not f.is_file():
                    continue
                text = f.read_text(errors="replace")
                updated = text.replace(f'"path": "{cwd}/', f'"path": "{worktree_path}/')
                if updated != text:
                    f.write_text(updated)
        else:
            print(f"warning: no Claude project found at {src}", file=sys.stderr)

    print(worktree_path)


if __name__ == "__main__":
    main()
