local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 12.0
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.scrollback_lines = 10000

return config
