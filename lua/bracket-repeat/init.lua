---@mod bracket-repeat.nvim placeholder
local M = {}

local api = vim.api

local default_config = {}

local loaded_config = default_config

local last_bracket = nil

local function repeat_last()
	print("repeating", last_bracket)
	last_bracket()
end

---@param config table user config
---@usage [[
---require('bracket-repeat').setup {
---}
---@usage ]]
M.setup = function(config)
	config = config or {}
	loaded_config = vim.tbl_deep_extend("keep", config, default_config)

	-- {
	-- 	buffer = 0,
	-- 	callback = <function 1>,
	-- 	desc = "Next error",
	-- 	expr = 0,
	-- 	lhs = "]g",
	-- 	lhsraw = "]g",
	-- 	lnum = 0,
	-- 	mode = "n",
	-- 	noremap = 1,
	-- 	nowait = 0,
	-- 	script = 0,
	-- 	sid = -8,
	-- 	silent = 1
	-- }

	-- XXX: hook to nvim_get_keymap for lazy binds
	-- XXX: both directions
	-- TODO: go over all keymaps and find all bracket binds
	local lhs = "]g"
	local keymaps = api.nvim_get_keymap("n")
	for _, keymap in ipairs(keymaps) do
		if keymap.lhs == lhs then
			local orig_cb = keymap.callback
			vim.keymap.del("n", lhs)
			vim.keymap.set("n", lhs, function()
				last_bracket = orig_cb
				orig_cb()
			end)
			vim.print(keymap)
		end
	end

	vim.keymap.set("n", ";", repeat_last)
end

return M
