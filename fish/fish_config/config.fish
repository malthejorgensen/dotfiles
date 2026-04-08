# Set locale
set -q LC_ALL; and set -e LC_ALL
set -Ux LC_ALL en_US.UTF-8
set -q LANG; and set -e LANG
set -Ux LANG en_US.UTF-8

# Many tools use `vi` by default, but `vi` will exit with a non-zero status code
# Instead we use `vim`.
# See: https://stackoverflow.com/q/66283714/118608
set -Ux EDITOR vim

set -Ux SHELL /opt/homebrew/bin/fish
set -gx SHELL /opt/homebrew/bin/fish

# Make fish the default shell on macOS (yes, this is _mostly_ safe)
# > sudo vim /etc/shells
# Put in a line with `/opt/homebrew/bin/fish`
# Save and quit (:wq)
# > chsh -s /opt/homebrew/bin/fish


# `less` config
# -S: Don't wrap lines
# -R: Allow colored input (parse ANSI codes)
#     This is required for `git log` to work.
# --quit-if-one-screen (or -F): Don't keep `less` open if the output fits in the
#                               terminal (espicially relevant if there's no 
#                               output -- in that case you don't want to have
#                               `less` just stay open on a blank screen)
set -Ux LESS '-S -R --quit-if-one-screen'

# Keybindings
# Ctrl-J erases from cursor to beginning of line
# -- breaks `poetry shell`
# bind \cj backward-kill-line

# Enable Homebrew
if [ -e /opt/homebrew/bin/brew ]
  eval (/opt/homebrew/bin/brew shellenv)
end

# Enable Macports (if installed)
if [ -e /opt/local/bin/port ]
  fish_add_path -g "/opt/local/bin"
  fish_add_path -g "/opt/local/sbin"
end

# Add ~/bin to $PATH
fish_add_path -g "$HOME/bin"

# Git prompt/statusline
# From: https://www.martinklepsch.org/posts/git-prompt-for-fish-shell.html
set __fish_git_prompt_showdirtystate 'yes'
set __fish_git_prompt_char_dirtystate '⚡'
function fish_prompt
  set last_status $status

  set_color $fish_color_cwd
  printf '%s' (prompt_pwd)
  # ^[[K:   
  # ^[[67C: 
  # ^[[38:  
  # ^[[m:   Reset all styles
  # \r:     cursor to line start
  # printf '^[[K^[[67C^[[38^[[m\r' (prompt_pwd)

  set_color normal

  printf '%s ' (__fish_git_prompt)

  set_color normal
end

function fish_right_prompt
  date '+%H:%M'
end

function list
  # Creates a list
  #
  # FROM: https://github.com/fish-shell/fish-shell/issues/445#issuecomment-145958769
  string join \n $argv
end


### Set $MANPATH
# We could use `path_helper`, but maybe doing it manually is faster (?)
# See https://discussions.apple.com/thread/2187861?tstart=0
# and https://github.com/fish-shell/fish-shell/issues/417
set --export MANPATH (cat /etc/manpaths) $MANPATH
for f in (find /etc/manpaths.d -type f)
  set --export MANPATH (cat $f) $MANPATH
end

function fishconf
  vim ~/.config/fish/config.fish
end

# cd to the path of the front Finder window
function cdf
  set target (osascript -e 'tell application "Finder" to if (count of Finder windows) > 0 then get POSIX path of (target of front Finder window as text)')
  if [ "$target" != "" ]
    cd "$target"; pwd
  else
    echo 'No Finder window found' >&2
  end
end

# `ssh-agent` does something very unintuitive
function ssh-agent
  echo '`ssh-agent` outputs bash-script that sets the environment variables `SSH_AUTH_SOCK` and `SSH_AGENT_PID`.'
  echo 'You most likely want to use `ssh-add` instead.'
  echo ''
  echo 'ssh-add -l          lists currently loaded identities/keys'
  echo 'ssh-add FILE        adds an identity/key to the list of loaded identities'
  echo 'ssh-add -d FILE     removes a currently loaded identity/key'

  #echo -n 'Run `ssh-agent`? (y/n)'
  read -p 'echo "Run `ssh-agent`? (y/n) "' -l answer
  if [ $answer = 'y' ]
    /usr/bin/ssh-agent
  end
end

# Sublime Text's `subl` command does not open files and directories in tmux
# under OS X
# (See: http://superuser.com/a/843631/268700)
alias subl 'reattach-to-user-namespace subl'


# You never want to `rm` something -- you want to put it in the trash
which trash >/dev/null; and alias rm 'trash'

# Always ask for confirmation for overwriting when using `mv`
function mv
  /bin/mv -i $argv
end
# Always ask for confirmation for overwriting when using `mv`
function cp
  /bin/cp -i $argv
end
# `sponge` (from `moreutils`) is _always_ dangerous. Never run it -- instead print a safer alternative.
function sponge
  echo '`sponge` is dangerous. If any previous command in the pipeline fails, `sponge` will delete the file.'
  echo 'Instead of `PIPELINE | sponge FILE` do `PIPELINE > FILE.tmp && mv FILE.tmp FILE`'
  return 1
end

# Make it easy to use find (in 99% of cases)
function ifind
  find . -iname "*$argv[1]*"
end

alias isodate "date '+%Y-%m-%dT%H:%M:%S'"

# `where` is a great ZSH command, unfortunately it doesn't exist in fish
alias where 'which -a'

# Don't wait for Emacs at the commandline
alias emacsclient 'emacsclient -n'

# Easily produce a filename like "2025-06-20-11-20-output-of-command.log"
alias logdate "date '+%Y-%m-%d-%H-%M'"

# git shortcuts
alias gc 'git checkout'
alias gco 'git checkout'
alias gcb 'git checkout -b'
alias gtb 'git checkout (git branch | tr -d " " | fzf)'
# alias gb 'git branch --show-current' # Works on git v2.22
alias gb 'git rev-parse --abbrev-ref HEAD' # Old Intel Macbook is on git v2.20
# alias gpr 'git pull --rebase'
alias grm 'git rebase master --autostash'
alias grmi 'git rebase -i master --autostash'
# alias git-rebase-origin 'git fetch; git rebase FETCH_HEAD' # WARNING: See note below
function git-rebase-origin
    if test (count $argv) -gt 0
        git fetch $argv[1]; git rebase $argv[1]/(gb)
    else
        set --local remote_name (git config branch.$(git name-rev --name-only HEAD).remote)
        # Normally, $remote_name will be "origin", but not always
        git fetch; git rebase $remote_name/(gb)
    end
  end
alias git-safe-pull git-rebase-origin
alias gpr git-safe-pull
alias git-merge-cleanup 'find -E . -regex \'.*_(BACKUP|BASE|LOCAL|REMOTE)_[0-9]{4}\.[^\.]+\' -print0 | xargs -0 rm'
alias gds "git diff --stat"
alias gdo "git diff origin/(gb)"
alias gfo 'git fetch origin'
alias gcp 'git cherry-pick'
alias glo "git log origin/(gb) --pretty=oneline"
alias glp "git log --pretty=oneline"
# Use the built-in `type` command to determine if a function with a given name
# exists. E.g. `type gpr`.
alias gsl 'git stash list | awk -F" " "/stash@{[0-9]+}: WIP on "(gb)":/"'
alias tsl 'tig stash --grep="on "(gb)'
# **** WARNING: `FETCH_HEAD` is dangerous ****
# `FETCH_HEAD` isn't relative to the current branch -- it is simply the most
# recently `git fetch`ed commit. So if you do:
#
#     git checkout main
#     git checkout my-branch
#     git log FETCH_HEAD
#
# you'll see the log for `main` -- not for `my-branch`.
# For that reason I no longer use the following aliases:
#
#     alias glo 'git log FETCH_HEAD' # git log origin/<branch>
#     alias gdo 'git diff FETCH_HEAD' # diff current branch with origin
function git-recent-branches
      git reflog | \
      egrep -io "moving from ([^[:space:]]+)" | \
      awk '{ print $3 }' | \
      awk ' !x[$0]++' | \
      egrep -v '^[a-f0-9]{40}$' | \
      # Only get branches that are "alive" (non-deleted)
      fgrep "$(git branch --format='%(refname:lstrip=2)')" | \
      # Only get 20 latest
      head -n20
end
function grp
  git-recent-branches | fzf
end
function gr
  git checkout (grp)
end
function gdr
  set --local __branch_to_delete (grp)
  read -n 1 --local -P "Delete branch \"$__branch_to_delete\"?"' (Y/n) ' __yes_no
  if test "$__yes_no" = 'Y' -o "$__yes_no" = 'y'
    git branch -D "$__branch_to_delete"
  end
end
function gtp
  git branch | sed -E 's/^.{2}//' | fzf
end
function gt
  git checkout (gtp)
end
function ggt
  # `git grep` excluding any test files
  # git grep $argv -- ':!*/tests/*' ':!test_*'
  git grep $argv -- ':!**/test_*'
end
function grex
  echo "/$argv[1]/$argv[2]/"
  uvx repx -i "/$argv[1]/$argv[2]/" (git grep -E -l "$argv[1]")
end


function smart-rebase
  # Rebases the branch from the top-most branch point (using `git rebase --onto`)
  #
  # This commands is often helpful when you have "stacked PRs" where one PR
  # branches off another. Rebasing normally would rebase all of the PRs, where
  # you're usually just interested in rebasing the topmost PR. This command does
  # exactly that, assuming that the PRs underneath haven't moved/changed.
  #
  # This is somewhat similar to `git neck` from https://leahneukirchen.org/blog/archive/2013/01/a-grab-bag-of-git-tricks.html,
  # where this commands rebases the "neck" and `git neck` just displays the
  # commits in the "neck".

  # We tell argparse about -h/--help and -b/--base - these are short and long forms of the same option.
  # The "--" here is mandatory, it tells it from where to read the arguments.
  argparse h/help b/base -- $argv
  # exit if argparse failed because it found an option it didn't recognize - it will print an error
  or return

  # If -h or --help is given, we print a little help text and return
  if set --query --local _flag_help
      echo "smart-rebase [-h|--help] <destination-branch>"
      echo ""
      echo "Rebases only commits from this branch that are on no other branch onto <destination-branch>"
      return 0
  end

  # `--decorate=full` shows `refs/heads` before branch names so that we can 
  # `--decorate-refs=refs/heads` filters out tags and remotes
  # `tail -n +2` skips the first line (current commit/branch)
  # `awk ...` search for commits that are on a branch, and then prints out the branch name
  # `head -n 1` grab the first branch name in the list
  set --local closest_parent_branch (
    git log --pretty=oneline \
            --decorate=short \
            --decorate-refs=refs/heads |  \
      tail -n +2 | \
      # awk does not expose regex capture groups (https://stackoverflow.com/a/2957781/118608)
      # But `gawk` does: gawk '/^[a-f0-9]{40} \(([^,)]+)/ { match($0, /^[a-f0-9]{40} \\(([^,)]+)/, matches); print(matches[1]) }' | \
      awk '/^[a-f0-9]{40} \(([^,)]+)/ { print(substr($2, 2, length($2)-2)) }' | \
      head -n 1
  )

  set --local base_branch $argv[1]
  if test -z "$base_branch"
    set --function base_branch $closest_parent_branch
  end

  set --local current_branch (gb)
  echo "This will run:

git rebase
  --onto $base_branch
  $closest_parent_branch
  $current_branch
"
  while read --nchars 1 -l response --prompt-str="Are you sure? (y/n) "
    or return 1 # if the read was aborted with ctrl-c/ctrl-d
    switch $response
        case y Y
            git rebase -i --onto $base_branch $closest_parent_branch $current_branch
            break
        case n N
            # We return from the function without printing
            echo 'Canceled.'
            return 1
        case '*'
            # We go through the while loop and ask again
            echo 'Invalid input'
            continue
    end
  end

  return 0
end

# See `git-unconflict` in `~/bin`
# function git-conflict-choose
#   set --local files (git diff --name-only | sort | uniq)
#   if test (count $files) -gt 0
#     git checkout -f $arg $files
#     git add $files
#   else
#     echo 'No conflicts found'
#   end
# end
# function currently-rebasing
#   test -e (git rev-parse --git-dir)/rebase-merge/done
# end
# 
# function git-conflict-ours
#   if currently-rebasing
#     # `--theirs` looks weird here, but it's correct -- git is weird like that
#     # when rebasing `--theirs` and `--ours` are flipped
#     git-conflict-choose --theirs
#   else
#     # when merging `--theirs` is theirs and `--ours` is ours
#     git-conflict-choose --ours
#   end
# end
# function git-conflict-theirs
#   if currently-rebasing
#     # `--ours` looks weird here, but it's correct -- git is weird like that
#     # when rebasing `--theirs` and `--ours` are flipped
#     git-conflict-choose --ours
#   else
#     # when merging `--theirs` is theirs and `--ours` is ours
#     git-conflict-choose --theirs
#   end
# end

# tig doesn't have `tig branches` / `tig tags` (https://github.com/jonas/tig/pull/509)
function tig
  if test "$argv[1]" = 'branch' -o "$argv[1]" = 'branches'
    command tig refs --branches
  else if test "$argv[1]" = 'tag' -o "$argv[1]" = 'tags'
    command tig refs --tags  
  else
    command tig $argv
  end
end

function grrep
  grep --color=always -r $argv . | less -R
end

# Easily find changed files between directories
function dirdiff-rsync
  rsync --dry-run --itemize-changes -r -v -a $argv
end

function gitgrepblame
  git grep --line "$argv[1]" | python -c 'for l in open(0).readlines(): s=l.split(":"); print(f"{s[0]} -L {s[1]},{s[1]}")' | xargs -L 1 git blame
end


# Update prompt when executing a command
#
# This makes it so that the "fish_right_prompt" states the time that the command
# was actually run, rather than when the prompt was printed.
#function reprint_prompt --on-event fish_preexec
#    # \033[F: Go to start of previous line (current prompt)
#    # \033[<$columns>G: Go $columns characters forwards
#    echo -e "\033[F\033["(math $COLUMNS - 4)"G"(fish_right_prompt)
#end
# This version also updates current git branch to what it was at the time when command
# was run, rather than the git branch from when the prompt was first printed.
# https://gist.github.com/malthejorgensen/c28017b317ee1e9027a361553eb3c2e5
# function reprint_prompt --on-event fish_preexec
#     return
#     # set -l _main_prompt (fish_prompt)(fish_indent --no-indent --ansi (echo -n "$argv" | psub))
#     set -l _prompt (fish_prompt)
#     set -l _command (fish_indent --no-indent --ansi (echo -n "$argv" | psub))
#     set -l _right_prompt (fish_right_prompt | tr -d '\n')
#     set -l _len_right_prompt (string length $_right_prompt)
#     set -l _len_prompt (string length "$_prompt")
#     set -l _len_command (string length "$argv")
#     set -l _num_lines (math 'ceil(('$_len_prompt + $_len_command')' / $COLUMNS')')
#     # echo -e -n "\033[10F                    --> "$_len_prompt $_prompt $_len_command $_command $_num_lines" <--"
#     # echo -e -n "\033[10B"
#     # Go to previous line (\033[F), clear line and print current time, then go to start of line (\r)
#     # Clearing the line is necessary in cases where the prompt has gotten shorter, since it
#     # was first printed (e.g. shorter git branch name). In that case, without clearing,
#     # parts of the old prompt or command would hang around.
#     echo -e -n "\033["$_num_lines"F"(string repeat --no-newline --count (math $COLUMNS - $_len_right_prompt) ' ')$_right_prompt'\r'
#     # Print prompt (to get current git branch)
#     echo "$_prompt""$_command"
# end

# DEPRECATED: Make `git flow` work (see: https://github.com/nvie/gitflow/issues/98)
# (I don't use `git flow` anymore)
# set --local __brew_prefix (brew --prefix gnu-getopt)
# set --export FLAGS_GETOPT_CMD "$__brew_prefix/bin/getopt"

# Python from Homebrew (Homebrew exposes a `python3.8`-executable not `python`)
fish_add_path -g '/usr/local/opt/python@3.8/libexec/bin'
# Ruby from Homebrew (Homebrew doesn't shadow macOS ruby by default)
fish_add_path -g '/usr/local/opt/ruby/bin'
# ... also show gems
fish_add_path -g '/usr/local/lib/ruby/gems/2.7.0/bin'

# DEPRECATED: Custom installation dir for `brew cask` (I don't do this anymore)
# set --export HOMEBREW_CASK_OPTS "--appdir=~/Applications"

# ASDF
# source ~/.asdf/asdf.fish
# ASDF Homebrew install
# if type -q brew
#   source (brew --prefix asdf)/libexec/asdf.fish
# end

# mise
fish_add_path -g "$HOME/.local/share/mise/shims"

# poetry
fish_add_path -g "$HOME/.local/bin" 

# cargo
fish_add_path -g "$HOME/.cargo/bin"

# Go / golang
fish_add_path -g "$HOME/go/bin"

# rbenv
#fish_add_path -g "$HOME/.rbenv/shims"

# PHP's composer
fish_add_path -g "$HOME/.composer/vendor/bin"

# OPAM configuration (OCaml)
# source /Users/malthe/.opam/opam-init/init.fish > /dev/null 2> /dev/null; or true

# virtualfish
# https://github.com/adambrenecki/virtualfish
#eval (python3 -m virtualfish)

# chruby
#source /usr/local/share/chruby/chruby.fish

# OpenJDK / Java
if [ -e /opt/local/bin/port ]
  # -- MacPorts
  fish_add_path -g '/Library/Java/JavaVirtualMachines/jdk-25-macports.jdk/Contents/Home/bin'
  set -Ux JAVA_HOME '/Library/Java/JavaVirtualMachines/jdk-25-macports.jdk/Contents/Home'
else
  # -- Homebrew
  fish_add_path -g "/opt/homebrew/opt/openjdk/bin"
end

# # nvm
# export NVM_DIR="$HOME/.nvm"
# function nvm
#   bass source "/usr/local/opt/nvm/nvm.sh" --no-use ';' nvm $argv
# end
# [ -s "/usr/local/opt/nvm/nvm.sh" ] && bass source "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
# [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && bass source "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

# Docker
fish_add_path -g "$HOME/.docker/bin"
fish_add_path -g "/Applications/Docker.app/Contents/Resources/bin" # Docker Desktop
set -Ux DOCKER_DEFAULT_PLATFORM linux/arm64

# rustup
# -- can be found in `./conf.d/rustup.fish`

# uv
# -- can be found in `./conf.d/uv.env.fish`

# DEPRECATED: Custom installation dir for `brew cask` (I don't do this anymore)
# Use Homebrew Postgres v11 instead of v12 for now
# set -g fish_user_paths "/usr/local/opt/postgresql@11/bin" $fish_user_paths
# Use Postgres v11 data directory (same as `postgres -D /usr/local/var/postgres11.1`)
# set -Ux PGDATA '/usr/local/var/postgres11.1'

# direnv
type -q -f direnv; and direnv hook fish | source

# Claude Code: Make it stay in the initial directory always
# -- this _should_ help it not getting confused about where it is.
set -Ux CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR 1

# OpenAI Codex: Use `.codex/config.toml` in current directory
# -- as of 2025-10-01 `codex` doesn't have per-project settings
function codex-local
  set -f CODEX_DIR "$(pwd)/.codex"
  if [ ! -e "$CODEX_DIR" ]
    read -l -P ".codex does not exist, do you want to import it from your global settings? [Y/n]" confirm

    if [ $status -ne 0 ]
      return
    end

    # Always make the `.codex`-dir and copy over `auth.json`
    mkdir "$CODEX_DIR"
    cp ~/.codex/auth.json "$CODEX_DIR/auth.json"

    if [ "$confirm" = 'Y' -o "$confirm" = 'y' ]
      cp ~/dotfiles/codex/config.toml "$CODEX_DIR/config.toml"
    end
  end
  # Codex always uses `zsh` on macOS, but our environment says `$SHELL=/opt/homebrew/bin/fish`
  # which in turn confuses Homebrew which is called in ~/.zprofile for `eval $(brew shellenv)`
  # 
  # See: https://github.com/openai/codex/issues/3823
  env SHELL=/bin/zsh CODEX_HOME="$CODEX_DIR" codex $argv
end

# pnpm
if type -q -f pnpm
  set -gx PNPM_HOME "/Users/malthejorgensen/Library/pnpm"
  if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
  end
end
# pnpm end
