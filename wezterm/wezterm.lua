-- Import the wezterm module
local wezterm = require 'wezterm'
-- Creates a config object which we will be adding our config to
local config = wezterm.config_builder()

-- See: https://alexplescan.com/posts/2024/08/10/wezterm/

local appearance = require 'appearance'

-- Spawn a fish shell in login mode
config.default_prog = { '/opt/homebrew/bin/fish', '-l' }

if appearance.is_dark() then
  config.color_scheme = 'Selenized Dark (Gogh)'
else
  config.color_scheme = 'Selenized Light (Gogh)'
end

-- Keep closing delimiters around a URL out of the clickable link. WezTerm's
-- default bare-URL rule permits `)` as the final character, which makes links
-- in Markdown and prose such as `[label](https://example.com)` open the wrong
-- address.
config.hyperlink_rules = {
  {
    regex = [[\((\w+://\S+)\)]],
    format = '$1',
    highlight = 1,
  },
  {
    regex = [[\[(\w+://\S+)\]]],
    format = '$1',
    highlight = 1,
  },
  {
    regex = [[\{(\w+://\S+)\}]],
    format = '$1',
    highlight = 1,
  },
  {
    regex = [[<(\w+://\S+)>]],
    format = '$1',
    highlight = 1,
  },
  {
    regex = [[\b\w+://\S+[/a-zA-Z0-9-]+]],
    format = '$0',
  },
  {
    regex = [[\b\w+@[\w-]+(\.[\w-]+)+\b]],
    format = 'mailto:$0',
  },
}

-- Table mapping keypresses to actions
config.keys = {
  -- Sends ESC + b and ESC + f sequence, which is used
  -- for telling your shell to jump back/forward.
  {
    -- When the left arrow is pressed
    key = 'LeftArrow',
    -- With the "Option" key modifier held down
    mods = 'OPT',
    -- Perform this action, in this case - sending ESC + B
    -- to the terminal
    action = wezterm.action.SendString '\x1bb',
  },
  {
    key = 'RightArrow',
    mods = 'OPT',
    action = wezterm.action.SendString '\x1bf',
  },
  {
    -- Cmd + , edits Wezterm config
    key = ',',
    mods = 'SUPER',
    action = wezterm.action.SpawnCommandInNewTab {
      cwd = wezterm.home_dir,
      args = { 'vim', wezterm.config_file },
    },
  },
  {
    key = 'LeftArrow',
    mods = 'SHIFT',
    action = wezterm.action.MoveTabRelative(-1)
  },
  {
    key = 'RightArrow',
    mods = 'SHIFT',
    action = wezterm.action.MoveTabRelative(1)
  },
  {
    key = 'Enter',
    mods = 'ALT',
    -- Claude Code needs Alt + Enter for newlines, but Wezterm's default is to
    -- "full screen" the window on that keypress
    -- Default: action = wezterm.action.ToggleFullScreen
    action = wezterm.action.DisableDefaultAssignment
    -- action = wezterm.action.Disable
  },
}

-- Keep text selection in WezTerm even when tmux has enabled mouse reporting.
-- This lets tmux handle the scroll wheel while Cmd + C can still copy the
-- selection, without copying it automatically when the mouse is released.
config.mouse_bindings = {
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.SelectTextAtMouseCursor 'Cell',
  },
  {
    event = { Drag = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.ExtendSelectionToMouseCursor 'Cell',
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.CompleteSelectionOrOpenLinkAtMouseCursor 'PrimarySelection',
  },
  {
    event = { Down = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.SelectTextAtMouseCursor 'Word',
  },
  {
    event = { Drag = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.ExtendSelectionToMouseCursor 'Word',
  },
  {
    event = { Up = { streak = 2, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.CompleteSelection 'PrimarySelection',
  },
  {
    event = { Down = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.SelectTextAtMouseCursor 'Line',
  },
  {
    event = { Drag = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.ExtendSelectionToMouseCursor 'Line',
  },
  {
    event = { Up = { streak = 3, button = 'Left' } },
    mods = 'NONE',
    mouse_reporting = true,
    action = wezterm.action.CompleteSelection 'PrimarySelection',
  },
}

return config
