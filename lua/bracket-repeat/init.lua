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

local is_bracket_binds_overridden = {}
-- Bind ']' and '[' to repeat until cursor moved
local function bind_bracket_repeat(bufnr)
	if not is_bracket_binds_overridden[bufnr] then
		vim.keymap.set("n", "]", function()
			repeat_last("next")
		end, { nowait = true, buffer = bufnr })

		vim.keymap.set("n", "[", function()
			repeat_last("prev")
		end, { nowait = true, buffer = bufnr })

		is_bracket_binds_overridden[bufnr] = true

		-- Delete bracket repeat binds after cursor moves
		api.nvim_create_autocmd("CursorMoved", {
			once = true,
			callback = function()
				vim.keymap.del("n", "]", { buffer = bufnr })
				vim.keymap.del("n", "[", { buffer = bufnr })

				is_bracket_binds_overridden[bufnr] = false
			end,
		})
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

		local bufnr = api.nvim_get_current_buf()
		-- Waiting to cursor to move from bracet movement to bind the repeat buttons
		api.nvim_create_autocmd("CursorMoved", {
			once = true,
			callback = function()
				bind_bracket_repeat(bufnr)
			end,
		})

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
	if keymap.buffer ~= 0 then
		vim.api.nvim_buf_del_keymap(keymap.buffer, keymap.mode, keymap.lhs)
	else
		vim.api.nvim_del_keymap(keymap.mode, keymap.lhs)
	end

	local opts = {
		desc = keymap.desc,
		expr = keymap.expr,
		noremap = keymap.noremap,
		nowait = keymap.nowait,
		script = keymap.script,
		silent = keymap.silent,
		replace_keycodes = keymap.replace_keycodes,
	}
	opts.callback = wrap_rhs(keymap.mode, keymap.rhs, keymap.callback, bracket_char)

	if keymap.buffer ~= 0 then
		api.nvim_buf_set_keymap(keymap.buffer, keymap.mode, keymap.lhs, "", opts)
	else
		api.nvim_set_keymap(keymap.mode, keymap.lhs, "", opts)
	end

	return opts.callback
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

	local keymaps = api.nvim_get_keymap("n")
	for _, keymap in ipairs(keymaps) do
		local bracket_char, dir = get_bracket_char(keymap.lhs)
		if bracket_char then
			binds_map[dir][bracket_char] = rebind_bracket(keymap, bracket_char)
		end
	end

	-- Hook to nvim_set_keymap and nvim_buf_set_keymap
	orig_api.nvim_set_keymap = api.nvim_set_keymap
	api.nvim_set_keymap = set_keymap_override

	orig_api.nvim_buf_set_keymap = api.nvim_buf_set_keymap
	api.nvim_buf_set_keymap = set_keymap_buf_override
end

return M
