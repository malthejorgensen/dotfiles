Settings precedence
-------------------

Settings are applied in order of precedence (higher on list overrides lower ones):

1. `managed-settings.json`: Enterprise managed policies / Deployed by IT. Cannot be overridden
2. Command line arguments: Temporary overrides for a specific session
3. `.claude/settings.local.json`: Rroject settings - Personal, not in source control
4. `.claude/settings.json`: Project settings - Team-shared added to source control
5. `~/.claude/settings.json`: Personal global settings

See: https://docs.claude.com/en/docs/claude-code/settings#settings-precedence

the `"permissions": {"deny": [...]}` list is "unioned" across files -- all
entries from all files end up in the "final" list that applies.

Environment variables in `settings.json`
----------------------------------------
It's not currently possible to **use** environment variables in `settings.json` (as of
2026-05-28) -- but it is possible to **set** them using the `env` key.

It would be quite nice to be able to refer to environment variables in `settings.json`
file.

One usecase is to expand the `$PATH` variable with e.g.:

    {
      "env": {
        "PATH_": "./frontend/node_modules/.bin:$PATH"
      }
    }

But that won't work!

**Issues**

- https://github.com/anthropics/claude-code/issues/4276
- https://github.com/anthropics/claude-code/issues/21473 (my own, showing that _some_ expansion is happening?)
