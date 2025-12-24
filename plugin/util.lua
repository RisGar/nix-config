if vim.g.vscode then
	return {}
end

-- snacks.nvim
require("snacks").setup({
	bigfile = { enabled = true },
	image = {
		enabled = true,
		math = {
			enabled = false,
		},
	},
	indent = { enabled = true },
	input = { enabled = true },
	picker = { enabled = true },
	rename = { enabled = true },
	scope = { enabled = true },
	toggle = { enabled = true },
	words = { enabled = true },
})

Snacks.toggle.inlay_hints():map("<leader>uh")
Snacks.toggle.diagnostics():map("<leader>ud")

local tsc = require("treesitter-context")
Snacks.toggle({
	name = "treesitter context",
	get = tsc.enabled,
	set = function(state)
		if state then
			tsc.enable()
		else
			tsc.disable()
		end
	end,
}):map("<leader>ut")

-- rename support for oil.nvim
vim.api.nvim_create_autocmd("User", {
	pattern = "OilActionsPost",
	callback = function(event)
		if event.data.actions.type == "move" then
			Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
		end
	end,
})

-- Quick Pickers
vim.keymap.set("n", "<leader><space>", function()
	Snacks.picker.smart()
end, { desc = "Smart Find Files" })
vim.keymap.set("n", "<leader>.", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>/", function()
	Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>:", function()
	Snacks.picker.command_history()
end, { desc = "Cmd History" })

-- Find
vim.keymap.set("n", "<leader>ff", function()
	Snacks.picker.files({ ignored = true, hidden = true })
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", function()
	Snacks.picker.git_files()
end, { desc = "Git Find" })
vim.keymap.set("n", "<leader>f.", function()
	Snacks.picker.recent()
end, { desc = "Recents" })
vim.keymap.set("n", "<leader>fb", function()
	Snacks.picker.buffers()
end, { desc = "Buffers" })
vim.keymap.set("n", "<leader>fc", function()
	Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find Config" })
vim.keymap.set("n", "<leader>fp", function()
	Snacks.picker.projects()
end, { desc = "Projects" })

-- Git
vim.keymap.set("n", "<leader>gl", function()
	Snacks.picker.git_log()
end, { desc = "Git Log" })
vim.keymap.set("n", "<leader>gL", function()
	Snacks.picker.git_log_line()
end, { desc = "Git Log Line" })
vim.keymap.set("n", "<leader>gf", function()
	Snacks.picker.git_log_file()
end, { desc = "Git Log File" })
vim.keymap.set("n", "<leader>gb", function()
	Snacks.picker.git_branches()
end, { desc = "Git Branches" })
vim.keymap.set("n", "<leader>gs", function()
	Snacks.picker.git_status()
end, { desc = "Git Status" })
vim.keymap.set("n", "<leader>gS", function()
	Snacks.picker.git_stash()
end, { desc = "Git Stash" })
vim.keymap.set("n", "<leader>gd", function()
	Snacks.picker.git_diff()
end, { desc = "Git Diff (Hunks)" })

-- Grep
vim.keymap.set("n", "<leader>sg", function()
	Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", "<leader>sb", function()
	Snacks.picker.lines()
end, { desc = "Buffer Lines" })
vim.keymap.set("n", "<leader>sB", function()
	Snacks.picker.grep_buffers()
end, { desc = "Grep Open Buffers" })

-- Search
vim.keymap.set("n", "<leader>su", function()
	Snacks.picker.undo()
end, { desc = "Undo History" })
vim.keymap.set("n", "<leader>sh", function()
	Snacks.picker.help()
end, { desc = "Help Pages" })
vim.keymap.set("n", "<leader>sk", function()
	Snacks.picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sc", function()
	Snacks.picker.command_history()
end, { desc = "Cmd History" })
vim.keymap.set("n", "<leader>s/", function()
	Snacks.picker.search_history()
end, { desc = "Search History" })
vim.keymap.set("n", "<leader>sC", function()
	Snacks.picker.commands()
end, { desc = "Commands" })
vim.keymap.set("n", "<leader>sM", function()
	Snacks.picker.man()
end, { desc = "Man Pages" })
vim.keymap.set("n", "<leader>ss", function()
	Snacks.picker.lsp_symbols()
end, { desc = "LSP Symbols" })
vim.keymap.set("n", "<leader>sS", function()
	Snacks.picker.lsp_workspace_symbols()
end, { desc = "LSP Workspace Symbols" })
vim.keymap.set("n", "<leader>sd", function()
	Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>sD", function()
	Snacks.picker.diagnostics_buffer()
end, { desc = "Buffer Diagnostics" })

-- LSP Gotos
vim.keymap.set("n", "gd", function()
	Snacks.picker.lsp_definitions()
end, { desc = "Goto Definition" })
vim.keymap.set("n", "gr", function()
	Snacks.picker.lsp_references()
end, { desc = "References", nowait = true })
vim.keymap.set("n", "gI", function()
	Snacks.picker.lsp_implementations()
end, { desc = "Goto Implementation" })
vim.keymap.set("n", "gy", function()
	Snacks.picker.lsp_type_definitions()
end, { desc = "Goto Type Definition" })

-- Words
vim.keymap.set({ "n", "t" }, "]]", function()
	Snacks.words.jump(vim.v.count1)
end, { desc = "Next Reference" })
vim.keymap.set({ "n", "t" }, "[[", function()
	Snacks.words.jump(-vim.v.count1)
end, { desc = "Prev Reference" })

-- devcontainers
require("devcontainer").setup({
	autocommands = {
		--  automatically start containers when devcontainer.json is available
		init = true,
		--  automatically remove any started containers and any built images when exiting vim
		clean = true,
		--  automatically restart containers when devcontainer.json file is updated
		update = true,
	},
	-- disable recursive search
	-- in that case only .devcontainer.json and .devcontainer/devcontainer.json files will be checked relative
	-- to the directory provided by config_search_start
	disable_recursive_config_search = true,
	-- By default all mounts are added (config, data and state)
	-- This can be changed to disable mounts or change their options
	-- This can be useful to mount local configuration
	-- And any other mounts when attaching to containers with this plugin
	attach_mounts = {
		neovim_config = {
			-- enables mounting local config to /root/.config/nvim in container
			enabled = true,
			-- makes mount readonly in container
			options = { "readonly" },
		},
		neovim_data = {
			-- enables mounting local data to /root/.local/share/nvim in container
			enabled = true,
			-- no options by default
			options = {},
		},
		neovim_state = {
			-- enables mounting local state to /root/.local/state/nvim in container
			enabled = true,
			-- no options by default
			options = {},
		},
	},
})
