function wk
    set -l destination (wk_impl $argv)
    or return

    if test -n "$destination"
        cd -- "$destination"
    end
end
