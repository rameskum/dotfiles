local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.initial_cols = 120
config.initial_rows = 28
config.enable_scroll_bar = true

config.color_scheme = "Batman"

config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Hack Nerd Font Mono",
})
config.font_size = 13.0

config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.window_decorations = "RESIZE"

config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 10000

return config
