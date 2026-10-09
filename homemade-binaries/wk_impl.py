#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
import argparse
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


class ArgumentParser(argparse.ArgumentParser):
    def print_help(self, file=None):
        super().print_help(file or sys.stderr)


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

    subprocess.run(
        ["git", "worktree", "remove", str(Path.cwd())],
        check=True,
        stdout=sys.stderr,
    )
    print(main_repo_root)


def main():
    parser = ArgumentParser(
        prog="wk", description="Create, list and delete Git worktrees with ease"
    )
    parser.add_argument(
        "branch",
        nargs="?",
        help="git branch to go to (worktree and branch will be created if needed), or 'list'",
    )
    parser.add_argument("--delete", action="store_true", help="Delete worktree")
    parser.add_argument(
        "--claude", action="store_true", help="Create worktree in ~/.claude/projects"
    )
    args = parser.parse_args()

    if args.branch == "delete" or args.delete:
        cmd_delete()
        return

    if args.branch == "list":
        # stdout is reserved for the destination consumed by the Fish wrapper.
        subprocess.run(["git", "worktree", "list"], check=True, stdout=sys.stderr)
        return

    # Find git repo root
    result = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
    )
    if result.returncode != 0:
        print("error: not inside a git repository", file=sys.stderr)
        sys.exit(1)

    repo_root = Path(result.stdout.strip())

    if args.branch:
        result = subprocess.run(
            ["git", "worktree", "list", "--porcelain", "-z"],
            capture_output=True,
            text=True,
            check=True,
        )
        for worktree in result.stdout.split("\0\0"):
            fields = worktree.split("\0")
            if f"branch refs/heads/{args.branch}" in fields:
                print(fields[0].removeprefix("worktree "))
                return

    claude_src = None
    if args.claude:
        claude_dir = Path.home() / ".claude" / "projects"
        cwd = Path.cwd()
        claude_src = claude_dir / cwd.as_posix().replace("/", "-")
        if not claude_src.is_dir():
            print(f"error: no Claude project found at {claude_src}", file=sys.stderr)
            sys.exit(1)

    # Generate 6-char random lowercase alphanumeric name
    chars = string.ascii_lowercase + string.digits
    name = "".join(random.choices(chars, k=6))

    worktree_path = repo_root / ".worktrees" / name
    worktree_path.parent.mkdir(exist_ok=True)

    branch = args.branch
    if branch:
        branch_exists = (
            subprocess.run(
                ["git", "show-ref", "--verify", "--quiet", f"refs/heads/{branch}"],
                capture_output=True,
            ).returncode
            == 0
        )
        if branch_exists:
            cmd = ["git", "worktree", "add", str(worktree_path), branch]
        else:
            cmd = ["git", "worktree", "add", "-b", branch, str(worktree_path)]
    else:
        cmd = ["git", "worktree", "add", "--detach", str(worktree_path)]
        print(
            "Due to how `git worktree` works you are in a detached HEAD state. "
            "Run `git checkout -b <branch_name>` to get a branch :)",
            file=sys.stderr,
        )
    subprocess.run(cmd, check=True, stdout=sys.stderr)

    if claude_src:
        dst = claude_dir / worktree_path.as_posix().replace("/", "-")
        shutil.copytree(claude_src, dst)
        # Replace
        for f in dst.rglob("*"):
            if not f.is_file():
                continue
            text = f.read_text(errors="replace")
            updated = text.replace(f'"path": "{cwd}/', f'"path": "{worktree_path}/')
            if updated != text:
                f.write_text(updated)

    print(worktree_path)


if __name__ == "__main__":
    main()
