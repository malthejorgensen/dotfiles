## Hooks
We set `hooksPath` in the global `~/.gitconfig`. This makes it so that **hooks
in repositories are never run!**. So to ensure hooks in the invididual
repositories still work we have "shim" hooks that always call the hooks in the
local repository first. Then you can add any extra _global_ logic you'd like
after that initial call in the shims.

**References:**
- <https://github.com/pre-commit/pre-commit/issues/1198#issuecomment-547521278>

The Git LFS calls in `post-checkout`, `post-commit`, `post-merge`, and
`pre-push` run only when an indexed `.gitattributes` file (including nested
ones) contains `filter=lfs`. Global LFS filter configuration alone does not
enable them. Repositories with LFS tracking rules still require `git-lfs` on
`PATH`. The other pre-push checks run regardless of LFS usage.

### Currently used hooks (non-shims)
- `pre-push`: Checks for "!", "fixup" and "WIP" in commits before pushing

## Stacked PRs / diffs / branches
A "cheap" way to get Stacked PRs is to use the `--update-refs` flag to
on `git rebase`. This will update parent branches (higher up in the
stack automatically).

What you need to do is a `git rebase --update-refs` from the top-most branch.
So if the stack is `new-landing-page-ab-test`, `new-landing-page`, `main`
you want to rebase at `new-landing-page-ab-test` and then you'll automatically
have  `new-landing-page` be updated.

This is now set as a global git setting, so it's implicitly passed on every rebase.

[Source](https://medium.com/@bruce.ho98/a-better-way-to-rebase-stacked-prs-aa9b4dc600f1).

## Tips & Tricks

### Exit vim with non-zero (error) exit code
To exit vim with a non-zero exit code, enter the command:

    :cq<Enter>

This is more of a `vim` tip but useful when you don't want to do that merge,
cherry-pick, interactive rebase or whatever it might be.

### How do I reformat all commits on a branch?

```bash
git rebase \
  --strategy-option=theirs \
  --exec '<formatting/linting command here>; git add --update; git commit --amend --no-edit' <base branch, e.g. "main" or "master">
```

**WARNING:** Using `cd <some directory` in `--exec` is _really_ dangerous. It will somehow
remove all files from the commit and you can't use `git rebase --abort` to get out.
If you end up in this situation do `git add (git ls-tree -r --name-only main)` and
then `git rebase --abort`. But maybe start by not getting into that situation in
the first place (by keeping `cd`) out of your `--exec`.

See: https://stackoverflow.com/questions/76945493/how-do-i-format-all-commits-in-a-branch/76945494#76945494

## Git internals (advanced)

### How do I read files in `.git/objects`?
Do

  git cat-file -p <hash>
