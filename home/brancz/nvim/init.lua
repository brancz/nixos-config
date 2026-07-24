-- home/brancz/nvim/init.lua
-- Plugins are installed by Nix (already on packpath) — this file only configures.

-- options ---------------------------------------------------------------
vim.g.mapleader = "," -- muscle memory from the old vimrc
local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.termguicolors = true
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.updatetime = 250
o.clipboard = "unnamedplus"

vim.cmd.colorscheme("catppuccin-mocha")

-- treesitter ------------------------------------------------------------
-- nixpkgs ships the `main` rewrite of nvim-treesitter, which dropped the old
-- `nvim-treesitter.configs` module: there is no setup() to call for highlight
-- and indent any more. Parsers are baked in by withPlugins (already on rtp,
-- nothing to :TSInstall), so we just start treesitter per buffer.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(ev)
    -- only for filetypes we actually have a parser for; pcall keeps a missing
    -- one from erroring out on every buffer of that type.
    if not pcall(vim.treesitter.start, ev.buf) then
      return
    end
    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- completion ------------------------------------------------------------
local cmp = require("cmp")
cmp.setup({
  snippet = {
    expand = function(args) require("luasnip").lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<CR>"] = cmp.mapping.confirm({ select = true }),
    ["<Tab>"] = cmp.mapping.select_next_item(),
    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
    { name = "path" },
  }),
})

-- LSP (non-rust; rust is handled by rustaceanvim automatically) ---------
local caps = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("nil_ls", { capabilities = caps })
vim.lsp.config("lua_ls", { capabilities = caps })
vim.lsp.config("gopls", { capabilities = caps })
vim.lsp.enable({ "nil_ls", "lua_ls", "gopls" })

-- rustaceanvim: zero setup needed; tweak via vim.g.rustaceanvim if desired
vim.g.rustaceanvim = {
  server = {
    default_settings = {
      ["rust-analyzer"] = {
        cargo = { features = "all" },
        check = { command = "clippy" },
      },
    },
  },
}

-- keymaps ---------------------------------------------------------------
local tb = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", tb.find_files)
vim.keymap.set("n", "<leader>fg", tb.live_grep)
vim.keymap.set("n", "<leader>fb", tb.buffers)
vim.keymap.set("n", "gd", vim.lsp.buf.definition)
vim.keymap.set("n", "gr", tb.lsp_references)
vim.keymap.set("n", "K", vim.lsp.buf.hover)
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "markdown preview (browser)" })
require("telescope").load_extension("fzf")

-- formatting ------------------------------------------------------------
require("conform").setup({
  formatters_by_ft = {
    rust = { "rustfmt" },
    nix = { "nixfmt" },
    lua = { "stylua" },
  },
  format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
})

require("gitsigns").setup()
require("lualine").setup()
