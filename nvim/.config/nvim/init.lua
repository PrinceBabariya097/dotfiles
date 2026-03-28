-- ============================================
-- 1. FILETYPE DETECTION
-- ============================================
vim.filetype.add({
  extension = {
    gowork = "gowork",
    gotmpl = "gotmpl",
  }
})

-- ============================================
-- 2. LEADER KEY
-- ============================================
vim.g.mapleader = " "

-- ============================================
-- 3. BASIC SETTINGS
-- ============================================
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.tabstop        = 2
vim.opt.shiftwidth     = 2
vim.opt.expandtab      = true
vim.opt.clipboard      = "unnamedplus"

-- ============================================
-- 4. KEYMAPS
-- ============================================

-- buffer navigation
vim.keymap.set("n", "<S-l>",      ":bnext<CR>",             { desc = "Next Buffer" })
vim.keymap.set("n", "<S-h>",      ":bprev<CR>",             { desc = "Prev Buffer" })
vim.keymap.set("n", "<leader>bd", ":bdelete<CR>",           { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>bD", ":bdelete!<CR>",          { desc = "Force Delete Buffer" })
vim.keymap.set("n", "<leader>bb", ":Telescope buffers<CR>", { desc = "Switch Buffer" })

-- file tree
vim.keymap.set("n", "<leader>fe", ":NvimTreeToggle<CR>",    { desc = "Toggle File Explorer" })

-- telescope
vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "Find Files" })
vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>",  { desc = "Grep in Files" })
vim.keymap.set("n", "<leader>fr", ":Telescope oldfiles<CR>",   { desc = "Recent Files" })
vim.keymap.set("n", "<leader>fn", ":enew<CR>",                 { desc = "New File" })

-- lsp
vim.keymap.set("n", "gd",         vim.lsp.buf.definition,    { desc = "Go to Definition" })
vim.keymap.set("n", "gr",         vim.lsp.buf.references,    { desc = "Go to References" })
vim.keymap.set("n", "K",          vim.lsp.buf.hover,         { desc = "Hover Docs" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action,   { desc = "Code Action" })
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename,        { desc = "Rename Symbol" })

-- diagnostics
vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show Error" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next,  { desc = "Next Error" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev,  { desc = "Prev Error" })

-- window navigation
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Left Window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Right Window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Lower Window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Upper Window" })

-- resize
vim.keymap.set("n", "<C-Up>",    ":resize +2<CR>",          { desc = "Increase Height" })
vim.keymap.set("n", "<C-Down>",  ":resize -2<CR>",          { desc = "Decrease Height" })
vim.keymap.set("n", "<C-Left>",  ":vertical resize -2<CR>", { desc = "Decrease Width" })
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase Width" })

-- indent
vim.keymap.set("v", "<", "<gv",         { desc = "Indent Left" })
vim.keymap.set("v", ">", ">gv",         { desc = "Indent Right" })

-- move lines
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==",      { desc = "Move Line Down" })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==",      { desc = "Move Line Up" })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv",  { desc = "Move Selection Down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv",  { desc = "Move Selection Up" })

-- save / quit
vim.keymap.set("n", "<leader>w",  ":w<CR>",   { desc = "Save" })
vim.keymap.set("n", "<leader>wq", ":wq<CR>",  { desc = "Save and Quit" })
vim.keymap.set("n", "<leader>q",  ":q<CR>",   { desc = "Quit" })
vim.keymap.set("n", "<leader>Q",  ":qa!<CR>", { desc = "Force Quit All" })

-- ============================================
-- 5. BOOTSTRAP LAZY.NVIM
-- ============================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================
-- 6. PLUGINS
-- ============================================
require("lazy").setup({

  -- file explorer
  { "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end
  },

  -- fuzzy finder
  { "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" }
  },

  -- treesitter
  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate"
  },

  -- lspconfig
  { "neovim/nvim-lspconfig" },

  -- mason
  { "williamboman/mason.nvim" },
  { "williamboman/mason-lspconfig.nvim" },

  -- noice (command palette UI) -- wilder removed, noice is enough
  { "folke/noice.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        presets = {
          command_palette = true,
        },
      })
    end
  },

  -- autocomplete
  { "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<Tab>"]     = cmp.mapping.select_next_item(),
          ["<S-Tab>"]   = cmp.mapping.select_prev_item(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<C-e>"]     = cmp.mapping.abort(),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      local servers = {
        "ts_ls", "lua_ls", "pyright",
        "clangd", "bashls", "html",
        "cssls", "jsonls",
      }
      for _, server in ipairs(servers) do
        vim.lsp.config(server, { capabilities = capabilities })
        vim.lsp.enable(server)
      end

      vim.lsp.config("gopls", {
        filetypes    = { "go", "gomod" },
        capabilities = capabilities,
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders    = true,
            analyses = { unusedparams = true },
          },
        },
      })
      vim.lsp.enable("gopls")
    end
  },

})

-- ============================================
-- 7. MASON SETUP
-- ============================================
require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = {
    "ts_ls", "lua_ls", "pyright",
    "clangd", "gopls", "bashls",
    "html", "cssls", "jsonls",
  },
  automatic_installation = true,
})
