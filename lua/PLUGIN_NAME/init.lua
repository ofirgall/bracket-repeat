---@mod {PLUGIN_NAME}.nvim {PLUGIN_DESCRIPTION}
local M = {}

local api = vim.api

local default_config = {
}

local loaded_config = default_config

---@param config table user config
---@usage [[
---require('{PLUGIN_NAME}').setup {
---}
---@usage ]]
M.setup = function(config)
    config = config or {}
    loaded_config = vim.tbl_deep_extend('keep', config, default_config)
end

return M
