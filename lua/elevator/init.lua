local M = {}

M.contexts = {}
M.active = {}
M.current_floor = nil

-- =========================================================
-- UTIL
-- =========================================================
local function tbl_contains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then
            return true
        end
    end
    return false
end

-- =========================================================
-- CONTEXT MANAGEMENT
-- =========================================================
function M.add_context(name, ctx)
    M.contexts[name] = ctx
    local group = vim.api.nvim_create_augroup("Elevator", { clear = false })

    for _, event in ipairs(ctx.events or {}) do
        vim.api.nvim_create_autocmd(event, {
            group = group,
            callback = function()
                M.check_context(name, ctx)
            end,
        })
    end
end

function M.remove_context(name)
    if M.contexts[name] then
        M.contexts[name] = nil
        M.active[name] = nil
        if M.current_floor == name then
            M.current_floor = nil
            M.resolve_floor()
        end
    end
end

-- =========================================================
-- FLOOR RESOLUTION
-- =========================================================
function M.check_context(name, context)
    local is_active = context.match and context.match() or false

    -- Activate keymaps if the context matches and is not already active
    if is_active and not context._active then
        for mode, map in pairs(context.mappings or {}) do
            for lhs, rhs in pairs(map) do
                vim.keymap.set(
                    mode,
                    lhs,
                    rhs,
                    { noremap = true, silent = true }
                )
            end
        end
        context._active = true
        M.active[name] = context
        -- update current_floor if higher priority
        if
            not M.current_floor
            or context.priority
                > (M.contexts[M.current_floor] and M.contexts[M.current_floor].priority or 0)
        then
            M.current_floor = name
        end

    -- Deactivate keymaps if the context no longer matches but was active
    elseif context._active and not is_active then
        for mode, map in pairs(context.mappings or {}) do
            for lhs, _ in pairs(map) do
                vim.keymap.del(mode, lhs)
            end
        end
        context._active = false
        M.active[name] = nil

        -- recalc current_floor if needed
        M.current_floor = nil
        for floor_name, ctx in pairs(M.active) do
            if
                not M.current_floor
                or ctx.priority > M.active[M.current_floor].priority
            then
                M.current_floor = floor_name
            end
        end
    end
end

function M.resolve_floor()
    local top, top_prio = nil, -math.huge
    for name, _ in pairs(M.active) do
        local ctx = M.contexts[name]
        if ctx.priority > top_prio then
            top, top_prio = name, ctx.priority
        end
    end

    if top ~= M.current_floor then
        M.swap_mappings(M.current_floor, top)
        M.current_floor = top
    end
end

-- =========================================================
-- MAPPINGS
-- =========================================================
function M.swap_mappings(old, new)
    -- restore old
    if old then
        local ctx = M.contexts[old]
        if ctx and ctx.mappings then
            for mode, maps in pairs(ctx.mappings) do
                for lhs, _ in pairs(maps) do
                    pcall(vim.keymap.del, mode, lhs, { buffer = 0 })
                end
            end
        end
    end

    -- apply new
    if new then
        local ctx = M.contexts[new]
        if ctx and ctx.mappings then
            for mode, maps in pairs(ctx.mappings) do
                for lhs, rhs in pairs(maps) do
                    vim.keymap.set(mode, lhs, rhs, { buffer = 0 })
                end
            end
        end
    end
end

-- =========================================================
-- PUBLIC API
-- =========================================================
function M.setup(opts)
    opts = opts or {}
    M.contexts = {}

    -- clear previous autocmds
    vim.api.nvim_create_augroup("Elevator", { clear = true })

    for name, ctx in pairs(opts.contexts or {}) do
        M.add_context(name, ctx)
    end

    -- user commands
    vim.api.nvim_create_user_command("ElevatorAddContext", function(args)
        local ctx = load("return " .. args.args)()
        M.add_context(ctx.name, ctx)
    end, { nargs = 1 })

    vim.api.nvim_create_user_command("ElevatorRemoveContext", function(args)
        M.remove_context(args.args)
    end, { nargs = 1 })

    vim.api.nvim_create_user_command("ElevatorFloors", function()
        print("Current floor: " .. (M.current_floor or "none"))
        print("Active contexts:")
        for name, _ in pairs(M.active) do
            print("  - " .. name)
        end
    end, {})
end

function M.clear()
    M.contexts = {}
    M.active = {}
    M.current_floor = nil
end

-- =========================================================
-- STATUSLINE HELPER
-- =========================================================
function M.statusline()
    return M.current_floor and ("[Elevator:" .. M.current_floor .. "]") or ""
end

return M
