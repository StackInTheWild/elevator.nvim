local Elevator = require("elevator")
local eq = assert.are.same

describe("elevator.nvim", function()
    before_each(function()
        Elevator.clear() -- make sure state is clean
    end)

    it("adds a context dynamically", function()
        Elevator.add_context("test", {
            events = { "BufEnter" },
            priority = 10,
            match = function()
                return true
            end,
            mappings = { n = { ["<leader>x"] = "echo 'test'" } },
        })

        eq(true, Elevator.contexts["test"] ~= nil)
    end)

    it("removes a context dynamically", function()
        Elevator.add_context("test", {
            events = { "BufEnter" },
            priority = 10,
            match = function()
                return true
            end,
        })

        Elevator.remove_context("test")
        eq(nil, Elevator.contexts["test"])
    end)

    it("resolves the highest priority floor", function()
        Elevator.add_context("low", {
            events = { "BufEnter" },
            priority = 5,
            match = function()
                return true
            end,
        })

        Elevator.add_context("high", {
            events = { "BufEnter" },
            priority = 10,
            match = function()
                return true
            end,
        })

        -- Manually trigger check
        Elevator.check_context("low", Elevator.contexts["low"])
        Elevator.check_context("high", Elevator.contexts["high"])

        eq("high", Elevator.current_floor)
    end)

    it("applies keymaps when context is active", function()
        Elevator.add_context("keymap_test", {
            events = { "BufEnter" },
            priority = 10,
            match = function()
                return true
            end,
            mappings = { n = { ["<leader>k"] = "<cmd>echo 'hello'<cr>" } },
        })

        -- Trigger the context
        Elevator.check_context("keymap_test", Elevator.contexts["keymap_test"])

        local exists = vim.fn.maparg("<leader>k", "n") ~= ""
        eq(true, exists)
    end)

    it("removes keymaps when context deactivates", function()
        local active = true
        Elevator.add_context("keymap_test", {
            events = { "BufEnter" },
            priority = 10,
            match = function()
                return active
            end,
            mappings = { n = { ["<leader>k"] = "<cmd>echo 'hello'<cr>" } },
        })

        -- Activate keymaps
        Elevator.check_context("keymap_test", Elevator.contexts["keymap_test"])
        local exists = vim.fn.maparg("<leader>k", "n") ~= ""
        assert.are.same(true, exists)

        -- Deactivate context
        active = false
        Elevator.check_context("keymap_test", Elevator.contexts["keymap_test"])
        exists = vim.fn.maparg("<leader>k", "n") ~= ""
        assert.are.same(false, exists)
    end)
end)
