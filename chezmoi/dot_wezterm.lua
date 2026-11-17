-- One WezTerm config for macOS, Linux and Windows (~/.wezterm.lua).
-- Managed by chezmoi (rameskum/dotfiles).
local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local is_mac = wezterm.target_triple:find("darwin") ~= nil
local is_windows = wezterm.target_triple:find("windows") ~= nil

config.initial_cols = 120
config.initial_rows = 28
config.enable_scroll_bar = true

config.color_scheme = "rose-pine-moon"

-- The one Nerd Font, installed by the chezmoi install script on each OS.
-- WezTerm's built-in fallback fonts cover anything it does not have.
config.font = wezterm.font_with_fallback({
  "JetBrainsMono Nerd Font",
  "JetBrains Mono",
})
config.font_size = 15.0

config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = "RESIZE"

config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000

if is_windows then
  config.default_prog = { "pwsh.exe", "-NoLogo" }
end

-- Same muscle memory everywhere: CMD on macOS, CTRL+SHIFT elsewhere
-- (plain CTRL is the shell's).
local mod = is_mac and "CMD" or "CTRL|SHIFT"
config.keys = {
  { key = "d", mods = mod, action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
  { key = "d", mods = mod .. "|ALT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "w", mods = mod, action = act.CloseCurrentPane({ confirm = true }) },
  { key = "LeftArrow", mods = mod .. "|ALT", action = act.ActivatePaneDirection("Left") },
  { key = "RightArrow", mods = mod .. "|ALT", action = act.ActivatePaneDirection("Right") },
  { key = "UpArrow", mods = mod .. "|ALT", action = act.ActivatePaneDirection("Up") },
  { key = "DownArrow", mods = mod .. "|ALT", action = act.ActivatePaneDirection("Down") },
}

return config
