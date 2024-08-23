---@mod bracket-repeat.nvim placeholder
local M = {}

local api = vim.api
local orig_api = {}

local default_config = {}

local loaded_config = default_config

local last_bracket = nil
local binds_map = {
	next = {},
	prev = {},
}

local function repeat_last(dir)
	local cb = binds_map[dir][last_bracket]
	if cb ~= nil then
		cb()
	end
end

local function wrap_rhs(mode, rhs, callback, bracket_char)
	local orig_cb = nil
	if callback then
		orig_cb = callback
	else
		orig_cb = function()
			vim.api.nvim_feedkeys(rhs, mode, true)
		end
	end

	return function()
		last_bracket = bracket_char
		orig_cb()
	end
end

---@param lhs string
local function get_bracket_char(lhs)
	if #lhs < 2 then
		return nil, false
	end
	local first = lhs:sub(1, 1)
	if first == "]" then
		return lhs:sub(2), "next"
	end

	if first == "[" then
		return lhs:sub(2), "prev"
	end

	return nil
end

local function rebind_bracket(keymap, bracket_char)
	local cb = wrap_rhs(keymap.mode, keymap.rhs, keymap.callback, bracket_char)
	vim.keymap.del(keymap.mode, keymap.lhs)
	vim.keymap.set(keymap.mode, keymap.lhs, cb)

	return cb
end

local function set_keymap_override(mode, lhs, rhs, opts)
	local bracket_char, dir = get_bracket_char(lhs)
	if bracket_char then
		opts.callback = wrap_rhs(mode, rhs, opts.callback, bracket_char)
		binds_map[dir][bracket_char] = opts.callback

		orig_api.nvim_set_keymap(mode, lhs, "", opts)
	else
		orig_api.nvim_set_keymap(mode, lhs, rhs, opts)
	end
end

local function set_keymap_buf_override(buffer, mode, lhs, rhs, opts)
	local bracket_char, dir = get_bracket_char(lhs)
	if bracket_char then
		opts.callback = wrap_rhs(mode, rhs, opts.callback, bracket_char)
		binds_map[dir][bracket_char] = opts.callback

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

	-- XXX: config next and prev
	-- XXX: try to repeat only with []
	-- XXX: check keymap opts are relied ok (desc, expr and such)
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

	local keymaps = api.nvim_get_keymap("n")
	for _, keymap in ipairs(keymaps) do
		local bracket_char, dir = get_bracket_char(keymap.lhs)
		if bracket_char then
			binds_map[dir][bracket_char] = rebind_bracket(keymap, bracket_char)
		end
	end

	vim.keymap.set("n", ";", function()
		repeat_last("next")
	end)
	vim.keymap.set("n", ",", function()
		repeat_last("prev")
	end)

	-- Hook to nvim_set_keymap and nvim_buf_set_keymap
	orig_api.nvim_set_keymap = api.nvim_set_keymap
	api.nvim_set_keymap = set_keymap_override

	orig_api.nvim_buf_set_keymap = api.nvim_buf_set_keymap
	api.nvim_buf_set_keymap = set_keymap_buf_override
end

return M
