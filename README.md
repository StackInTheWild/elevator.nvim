# 🛗 elevator.nvim

**Context-aware keymaps for Neovim.**  
Think of it as an *elevator*: you move between “floors” (contexts), and your keymaps change automatically depending on where you are.

---

## ✨ Features

- 🔑 Override existing keymaps **only when relevant**
- 🎯 Contexts are defined with a `match` function and one or more events
- ⏫ Supports **priority** (decide which context wins when multiple apply)
- ♻️ Contexts can be added or removed **at runtime**
- 🧩 Perfect for plugins that need temporary keymaps without conflicts

---

## 📦 Installation

Using **lazy.nvim**:

```lua
{
  "StackInTheWild/elevator.nvim",
  config = function()
    require("elevator").setup()
  end,
}
```

---

## 🛠️ Usage

### Define a context

```lua
local elevator = require("elevator")

elevator.add_context("git_conflict", {
  events = { "CursorMoved", "BufEnter" },
  priority = 80,
  match = function()
    local line = vim.api.nvim_get_current_line()
    return line:match("^<<<<<<<") or line:match("^=======") or line:match("^>>>>>>>")
  end,
  mappings = {
    n = {
      ["]x"] = "<cmd>HeadhunterNext<cr>",
      ["[x"] = "<cmd>HeadhunterPrevious<cr>",
      ["co"] = "<cmd>HeadhunterTakeHead<cr>",
      ["ci"] = "<cmd>HeadhunterTakeOrigin<cr>",
      ["cb"] = "<cmd>HeadhunterTakeBoth<cr>",
    },
  },
})
```

👉 When your cursor is inside a Git conflict, these keymaps override your normal ones.  
Move out of the conflict → your original keymaps come back automatically.

---

## 💡 More Examples

### 🐞 Debugging with nvim-dap

```lua
elevator.add_context("dap", {
  events = { "User" }, -- listens to User autocommands from nvim-dap
  priority = 90,
  match = function()
    return vim.g.in_debug_session == true
  end,
  mappings = {
    n = {
      ["<F5>"]  = "<cmd>DapContinue<cr>",
      ["<F10>"] = "<cmd>DapStepOver<cr>",
      ["<F11>"] = "<cmd>DapStepInto<cr>",
      ["<F12>"] = "<cmd>DapStepOut<cr>",
    },
  },
})
```

➡️ Debug keymaps only exist **while debugging**. No pollution outside.

---

### 📜 Markdown Editing

```lua
elevator.add_context("markdown", {
  events = { "BufEnter" },
  priority = 10,
  match = function()
    return vim.bo.filetype == "markdown"
  end,
  mappings = {
    n = {
      ["<leader>p"] = "<cmd>MarkdownPreviewToggle<cr>",
    },
    i = {
      ["<C-b>"] = "****<Esc>F*i",
    },
  },
})
```

➡️ Editing Markdown gets special bindings, without touching other filetypes.

---

### 🔍 Telescope Inside Search

```lua
elevator.add_context("telescope", {
  events = { "BufEnter" },
  priority = 100,
  match = function()
    return vim.bo.filetype == "TelescopePrompt"
  end,
  mappings = {
    i = {
      ["<C-j>"] = "move_selection_next",
      ["<C-k>"] = "move_selection_previous",
    },
  },
})
```

➡️ Inside Telescope prompt, you override `<C-j>/<C-k>` just for navigation.

---

## ⚙️ Events

`events` are the Neovim autocommands that trigger re-checking a context.  
Common choices:

- **BufEnter** → whenever you enter a buffer (great for filetype-specific contexts)  
- **CursorMoved** → whenever you move around (great for “cursor is inside X” checks)  
- **User** → custom plugin signals. For example:
  - `nvim-dap` fires `User DapStarted`, `User DapStopped`, `User DapTerminated`
  - You can listen for these to toggle debug keymaps

👉 Pick the event(s) that best signal “my context might have changed.”

---

## 🔧 API

- `require("elevator").setup(opts?)` → initialize plugin
- `add_context(name, ctx)` → add a context at runtime
- `remove_context(name)` → unregister a context
- `contexts` → table of registered contexts
- `active` → currently active contexts
- `current_floor` → the one with highest priority right now

---

## ✅ Why?

Without elevator.nvim:
- Debug keymaps, Git conflict maps, or plugin shortcuts are always present
- They pollute your global keymap space
- They may conflict with your own bindings

With elevator.nvim:
- Keymaps only exist **when relevant**
- Conflicts vanish — `<F5>` can mean “run tests” normally and “continue debug” during debugging
- Your keyboard stays clean and consistent

---

## 📜 License

MIT
