-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action
-- local mux = wezterm.mux
-- This will hold the configuration.
local config = wezterm.config_builder()
-- local gpus = wezterm.gui.enumerate_gpus()
-- config.webgpu_preferred_adapter = gpus[1]
-- config.front_end = "WebGpu"

config.front_end = "OpenGL"
config.max_fps = 144
config.default_cursor_style = "SteadyBlock"
config.term = "xterm-256color" -- Set the terminal type

-- config.font = wezterm.font("Iosevka Custom")
-- config.font = wezterm.font("Monocraft Nerd Font")
config.font = wezterm.font("FiraCode Nerd Font Mono")
-- config.font = wezterm.font("JetBrains Mono Regular")
config.cell_width = 0.9
-- config.font = wezterm.font("Menlo Regular")
-- config.font = wezterm.font("Hasklig")
-- config.font = wezterm.font("Monoid Retina")
-- config.font = wezterm.font("InputMonoNarrow")
-- config.font = wezterm.font("mononoki Regular")
-- config.font = wezterm.font("Iosevka")
-- config.font = wezterm.font("M+ 1m")
-- config.font = wezterm.font("Hack Regular")
-- config.cell_width = 0.9
config.window_background_opacity = 0.9
config.prefer_egl = true
config.font_size = 12.0

config.window_padding = {
	left = 10,
	right = 10,
	top = 10,
	bottom = 10,
}

-- tabs
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
-- config.tab_bar_at_bottom = true

-- config.inactive_pane_hsb = {
-- 	saturation = 0.0,
-- 	brightness = 1.0,
-- }

-- This is where you actually apply your config choices
--

-- Function to switch between WSL2 and powershell
local function switch_shell(window, pane)
	local current_prog = pane:get_foreground_process_name()
	local new_prog = "wsl.exe"

	if current_prog and current_prog:find("wsl") then
		new_prog = "powershell.exe"
	end

	-- Open the new shell in a new tab
	window:perform_action(wezterm.action.SpawnCommandInNewTab({ args = { new_prog } }), pane)

	-- Small delay before closing the old pane
	wezterm.time.sleep(0.2)

	-- Close the current pane (after new tab opens)
	window:perform_action(wezterm.action.CloseCurrentPane({ confirm = false }), pane)
end

-- Function to automate lark workflow
local function setup_workspace(window, pane)
	pane:send_text("cd ~/projects/lark\r")

	window:perform_action(wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }), pane)

	wezterm.sleep(4000)

	local panes = window:panes()
	local lower_pane = panes[2]

	window:perform_action(wezterm.action.AdjustPaneSize({ "Down", 10 }), lower_pane)
	wezterm.sleep(2000)
	lower_pane:send_text("cd ~/projects/lark\r")
end

-- color scheme toggling
wezterm.on("toggle-colorscheme", function(window, pane)
	local overrides = window:get_config_overrides() or {}

	-- List of color schemes to cycle through
	local themes = {
		"Catppuccin Mocha",
		"Gruvbox Material (Gogh)",
		"One Dark (Gogh)", -- Available in WezTerm
		"Andromeda", -- Available in WezTerm
	}

	-- Get the current scheme or default to the first one
	local current_scheme = overrides.color_scheme or themes[1]

	-- Find the index of the current scheme
	local next_index = 1
	for i, scheme in ipairs(themes) do
		if scheme == current_scheme then
			next_index = i % #themes + 1 -- Move to the next theme
			break
		end
	end

	-- Apply the next theme
	overrides.color_scheme = themes[next_index]
	window:set_config_overrides(overrides)
end)

-- Trigger the workflow when the command 'lark dev' is run
wezterm.on("exec-command", function(window, pane)
	local args = pane:get_foreground_process_info().args
	if args and args[1] == "lark" and args[2] == "dev" then
		setup_workspace(window, pane)
	end
end)

-- keymaps
config.keys = {
	{
		key = "S",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(switch_shell),
	},
	{
		key = "f",
		mods = "CTRL|SHIFT",
		action = wezterm.action({ SpawnCommandInNewTab = { args = { "fzf" } } }),
	},
	{
		key = "E",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.EmitEvent("toggle-colorscheme"),
	},
	{
		key = "h",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	{
		key = "v",
		mods = "CTRL|SHIFT|ALT",
		action = wezterm.action.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},
	{
		key = "U",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "I",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "O",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	{
		key = "P",
		mods = "CTRL|SHIFT",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{ key = "9", mods = "CTRL", action = act.PaneSelect },
	{ key = "L", mods = "CTRL", action = act.ShowDebugOverlay },
	{
		key = "O",
		mods = "ALT|SHIFT",
		-- toggling opacity
		action = wezterm.action_callback(function(window, _)
			local overrides = window:get_config_overrides() or {}
			if overrides.window_background_opacity == 1.0 then
				overrides.window_background_opacity = 0.9
			else
				overrides.window_background_opacity = 1.0
			end
			window:set_config_overrides(overrides)
		end),
	},
	{
		key = "l",
		mods = "CTRL|SHIFT",
		action = wezterm.action_callback(function(window, pane)
			setup_workspace(window, pane)
		end),
	},
}

-- For example, changing the color scheme:
config.color_scheme = "Gruvbox Material (Gogh)"

config.window_frame = {
	font = wezterm.font({ family = "Iosevka Custom", weight = "Regular" }),
	active_titlebar_bg = "#0c0b0f",
	-- active_titlebar_bg = "#181616",
}

-- config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_decorations = "NONE | RESIZE"
-- config.default_prog = { "powershell.exe", "-NoLogo" }
config.default_prog = { "wsl.exe", "--distribution", "Ubuntu", "--cd", "~"  }
-- config.default_prog = { "C:\\Program Files\\Git\\bin\\bash.exe", "--login", "-i" }
config.initial_cols = 80
-- config.window_background_image = "C:/dev/misc/berk.png"
-- config.window_background_image_hsb = {
-- 	brightness = 0.1,
-- }

-- wezterm.on("gui-startup", function(cmd)
-- 	local args = {}
-- 	if cmd then
-- 		args = cmd.args
-- 	end
--
-- 	local tab, pane, window = mux.spawn_window(cmd or {})
-- 	-- window:gui_window():maximize()
-- 	-- window:gui_window():set_position(0, 0)
-- end)

-- and finally, return the configuration to wezterm
return config
