---@mod bracket-repeat.nvim placeholder
local M = {}

local api = vim.api
local orig_api = {}

local default_config = {}

local loaded_config = default_config

local last_bracket = nil

local function repeat_last()
	if last_bracket ~= nil then
		last_bracket()
	end
end

local function wrap_rhs(mode, rhs, callback)
	local orig_cb = nil
	if callback then
		orig_cb = callback
	else
		orig_cb = function()
			vim.api.nvim_feedkeys(rhs, mode, true)
		end
	end

	return function()
		last_bracket = orig_cb
		orig_cb()
	end
end

local function rebind_bracket(keymap)
	vim.keymap.del(keymap.mode, keymap.lhs)
	vim.keymap.set(keymap.mode, keymap.lhs, wrap_rhs(keymap.mode, keymap.rhs, keymap.callback))
end

local function set_keymap_override(mode, lhs, rhs, opts)
	if lhs == "]c" then
		opts.callback = wrap_rhs(mode, rhs, opts.callback)
		orig_api.nvim_set_keymap(mode, lhs, "", opts)
	else
		orig_api.nvim_set_keymap(mode, lhs, rhs, opts)
	end
end

local function set_keymap_buf_override(buffer, mode, lhs, rhs, opts)
	if lhs == "]c" then
		opts.callback = wrap_rhs(mode, rhs, opts.callback)
		orig_api.nvim_buf_set_keymap(buffer, mode, lhs, "", opts)
	else
		orig_api.nvim_buf_set_keymap(buffer, mode, lhs, rhs, opts)
	end
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

	-- XXX: both directions
	-- TODO: go over all keymaps and find all bracket binds
	local lhs = "]g"
	local keymaps = api.nvim_get_keymap("n")
	for _, keymap in ipairs(keymaps) do
		if keymap.lhs == lhs then
			rebind_bracket(keymap)
		end
	end

	vim.keymap.set("n", ";", repeat_last)

	-- Hook to nvim_set_keymap and nvim_buf_set_keymap
	orig_api.nvim_set_keymap = api.nvim_set_keymap
	api.nvim_set_keymap = set_keymap_override

	orig_api.nvim_buf_set_keymap = api.nvim_buf_set_keymap
	api.nvim_buf_set_keymap = set_keymap_buf_override
end

return M
