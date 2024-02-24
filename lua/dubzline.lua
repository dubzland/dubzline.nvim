local fn = vim.fn
local api = vim.api

local dubzline = {}

dubzline.config = {}

dubzline.colors = {
    active = "%#StatusLine#",
    inactive = "%#StatusLineNC#",
}

dubzline.trunc_width = setmetatable({
    mode = 80,
    git_status = 90,
    filename = 140,
    line_col = 60,
}, {
    __index = function()
        return 80
    end,
})

dubzline.modes = setmetatable({
    ["n"] = "NORMAL",
    ["no"] = "NORMAL*",
    ["v"] = "VISUAL",
    ["V"] = "VISUAL LINE",
    [""] = "VISUAL BLOCK",
    ["s"] = "SELECT",
    ["S"] = "SELECT LINE",
    [""] = "SELECT BLOCK",
    ["i"] = "INSERT",
    ["ic"] = "INSERT",
    ["R"] = "REPLACE",
    ["Rv"] = "VISUAL REPLACE",
    ["c"] = "COMMAND",
    ["cv"] = "VIM EX",
    ["ce"] = "EX",
    ["r"] = "PROMPT",
    ["rm"] = "MORE",
    ["r?"] = "CONFIRM",
    ["!"] = "SHELL",
    ["t"] = "TERMINAL",
    ["nt"] = "TERMINAL",
}, {
    __index = function()
        return "UNKNOWN" -- handle edge cases
    end,
})

local function current_mode_color()
    local current_mode = api.nvim_get_mode().mode
    if current_mode == "n" then
        return "%#StatuslineModeNormal#"
    elseif current_mode == "i" or current_mode == "ic" then
        return "%#StatuslineModeInsert#"
    elseif current_mode == "v" or current_mode == "V" or current_mode == "" then
        return "%#StatuslineModeVisual#"
    elseif current_mode == "R" then
        return "%#StatuslineModeReplace#"
    elseif current_mode == "c" then
        return "%#StatuslineModeCmdLine#"
    elseif current_mode == "t" or current_mode == "nt" then
        return "%#StatuslineModeTerminal#"
    else
        return "%#StatuslineModeNormal#"
    end
end

local function current_mode()
    local m = api.nvim_get_mode().mode
    return table.concat({
        current_mode_color(),
        string.format(" %s ", dubzline.modes[m]):upper(),
        "%#StatusLine#",
    })
end

local function git_status()
    local ok, _ = pcall(require, "gitsigns")
    if ok then
        local git_info = vim.b.gitsigns_status_dict
        if not git_info or git_info.head == "" then
            return ""
        end
        local added = git_info.added and ("%#GitSignsAdd#+" .. git_info.added .. " ") or ""
        local changed = git_info.changed and ("%#GitSignsChange#~" .. git_info.changed .. " ") or ""
        local removed = git_info.removed and ("%#GitSignsDelete#-" .. git_info.removed .. " ") or ""
        if git_info.added == 0 then
            added = ""
        end
        if git_info.changed == 0 then
            changed = ""
        end
        if git_info.removed == 0 then
            removed = ""
        end

        return table.concat({
            "%#Whitespace# ",
            added,
            changed,
            removed,
            " ",
            "%#GitSymbol# ",
            git_info.head,
            "%#Whitespace# ",
            "%#StatusLine#",
        })
    else
        return ""
    end
end

local function file_name()
    return "%f%m%r"
end

local function file_type()
    local name, ext = fn.expand("%:t"), fn.expand("%:e")
    local ok, icons = pcall(require, "nvim-web-devicons")
    if ok then
        local icon = icons.get_icon(name, ext, { default = true })
        local filetype = vim.bo.filetype

        if filetype == "" then
            return ""
        end
        return string.format(" %s %s ", icon, filetype):lower()
    else
        return ""
    end
end

local function line_info()
    if vim.bo.filetype == "alpha" then
        return ""
    end
    return " %P %l:%c "
end

local function lsp_info()
    local count = {}
    local levels = {
        errors = "Error",
        warnings = "Warn",
        info = "Info",
        hints = "Hint",
    }

    for k, level in pairs(levels) do
        count[k] = vim.tbl_count(vim.diagnostic.get(0, { severity = level }))
    end

    local errors = ""
    local warnings = ""
    local hints = ""
    local info = ""

    if count["errors"] ~= 0 then
        -- errors = string.format(' %%#LspDiagnosticsSignError#%s %s', dubzline.config.icons.lsp.error, count['errors'])
        errors = string.format(" %%#ErrorSign#%s %s", dubzline.config.icons.lsp.error, count["errors"])
    end
    if count["warnings"] ~= 0 then
        warnings = string.format(" %%#WarningSign#%s %s", dubzline.config.icons.lsp.warning, count["warnings"])
    end
    if count["hints"] ~= 0 then
        hints = string.format(" %%#HintSign#%s %s", dubzline.config.icons.lsp.hint, count["hints"])
    end
    if count["info"] ~= 0 then
        info = string.format(" %%#InfoSign#%s %s", dubzline.config.icons.lsp.info, count["info"])
    end

    local output = table.concat({
        errors,
        warnings,
        hints,
        info,
    })

    if string.len(output) > 0 then
        return table.concat({
            "%#Whitespace#",
            output,
            "%#Whitespace# ",
            "%#StatusLine#",
        })
    else
        return ""
    end
end

local function is_excluded(bufnr)
    local ft = api.nvim_buf_get_option(bufnr, "ft")
    local found = false
    for _, v in pairs(dubzline.config.excluded) do
        if v == ft then
            found = true
            break
        end
    end
    return found
end

dubzline.active = function()
    return table.concat({
        current_mode(),
        git_status(),
        "%=",
        file_name(),
        "%=",
        lsp_info(),
        file_type(),
        line_info(),
    })
end

dubzline.inactive = function()
    return "%#StatusLineNC#" .. file_name()
end

dubzline.assign = function(bufnr, state)
    if is_excluded(bufnr) then
        vim.opt_local.statusline = " "
        return
    end

    if state == "active" then
        vim.opt_local.statusline = "%!v:lua.require'dubzline'.active()"
    else
        vim.opt_local.statusline = "%!v:lua.require'dubzline'.inactive()"
    end
end

dubzline.default_config = function()
    return {
        excluded = {},
        icons = {
            lsp = {
                error = "",
                warning = "",
                hint = "⚑",
                info = "",
            },
        },
    }
end

dubzline.setup = function(config)
    dubzline.config = vim.tbl_deep_extend("force", dubzline.default_config(), config)

    local dubzlineGroup = api.nvim_create_augroup("StatuslineExt", { clear = true })

    api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
        pattern = "*",
        callback = function(evt)
            dubzline.assign(evt.buf, "active")
        end,
        group = dubzlineGroup,
    })

    api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
        pattern = { "*" },
        callback = function(evt)
            dubzline.assign(evt.buf, "inactive")
        end,
        group = dubzlineGroup,
    })

    local colors = dubzline.config.colors

    vim.api.nvim_set_hl(0, "StatuslineModeNormal", { fg = colors.gui04, bg = colors.gui01 })
    vim.api.nvim_set_hl(0, "StatuslineModeInsert", { fg = colors.gui0B, bg = colors.guibg })
    vim.api.nvim_set_hl(0, "StatuslineModeVisual", { fg = colors.gui0A, bg = colors.guibg })
    vim.api.nvim_set_hl(0, "StatuslineModeReplace", { fg = colors.gui08, bg = colors.guibg })
    vim.api.nvim_set_hl(0, "StatuslineModeCmdLine", { fg = colors.gui0C, bg = colors.gui02 })
    vim.api.nvim_set_hl(0, "StatuslineModeTerminal", { fg = colors.gui00, bg = colors.gui0C })
    vim.api.nvim_set_hl(0, "GitSymbol", { fg = colors.gui0D, bg = colors.guibg })
end

return dubzline

-- vim: foldmethod=marker
