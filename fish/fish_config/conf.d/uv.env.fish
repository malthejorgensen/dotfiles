if [ -e "$HOME/.local/bin/env.fish" ]
  source "$HOME/.local/bin/env.fish"
end

function uv
    # `uv`-shim to override behavior of `uv init`.
    #
    # When running `uv init` we want to add `exclude-newer = "2 weeks"`
    # automatically to `pyproject.toml`. This is for security reasons, to not
    # install the very, very latest version of packages.
    # This is to try and avoid poisoned packages.
    #
    # It'd be easier to add this to some sort of global `config.toml` for `uv`
    # but there isn't a global config for `uv` (as of 2026-05-19).
    if test "$argv[1]" = "init"
        # If you run `uv init` we
        command uv $argv
        or return

        set project_dir .
        for arg in $argv[2..-1]
            if not string match -q -- '-*' $arg
                set project_dir $arg
            end
        end

        printf '\n[tool.uv]\nexclude-newer = "2 weeks"\n' >> $project_dir/pyproject.toml
    else
        # If you run a different `uv`-subcommand just pass it through to `uv`.
        command uv $argv
    end
end
