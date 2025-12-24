-- on_attach via LspAttach autocommand (replaces per-server on_attach)
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        local bufnr = args.buf

        -- Put your on_attach keymaps and settings here
        -- Example:
        -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr })
        -- vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr })
        
        -- If you have a shared on_attach function, call it:
        -- require("plugins.configs.lspconfig").on_attach(client, bufnr)
    end,
})

-- Global capabilities (applied to all servers)
vim.lsp.config('*', {
    capabilities = require("plugins.configs.lspconfig").capabilities,
})

-- bash
vim.lsp.config('bashls', {
    filetypes = { "sh" },
    cmd = { "bash-language-server", "start" },
    single_file_support = true,
})

-- docker / containerfile
vim.lsp.config('dockerls', {
    filetypes = { "dockerfile", "containerfile" },
    cmd = { "docker-langserver", "--stdio" },
    single_file_support = true,
})

-- python
vim.lsp.config('pyright', {
    filetypes = { "python" },
    cmd = { "pyright-langserver", "--stdio" },
    single_file_support = true,
})

-- c
vim.lsp.config('clangd', {
    filetypes = { "c", "cpp", "cc", "objc", "objcpp", "cuda", "proto" },
    cmd = { "clangd" },
    single_file_support = true,
})

-- R
vim.lsp.config('r_language_server', {
    filetypes = { "r", "rmd" },
    cmd = { "R", "--slave", "-e", "languageserver::run()" },
    single_file_support = true,
})

-- Makefiles
vim.lsp.config('autotools_ls', {
    filetypes = { "config", "automake", "make" },
    cmd = { "autotools-language-server" },
    single_file_support = true,
})

-- perl
vim.lsp.config('perlnavigator', {
    filetypes = { "perl" },
    cmd = { "perlnavigator" },
    single_file_support = true,
})

-- haskell
vim.lsp.config('hls', {
    filetypes = { "haskell", "lhaskell" },
    cmd = { "haskell-language-server-wrapper", "--lsp" },
    single_file_support = true,
})

-- nim
vim.lsp.config('nim_langserver', {
    filetypes = { "nim" },
    cmd = { "nimlangserver", "--lsp" },
    single_file_support = true,
})

-- Enable all configured servers
vim.lsp.enable({
    'bashls',
    'dockerls',
    'pyright',
    'clangd',
    'r_language_server',
    'autotools_ls',
    'perlnavigator',
    'hls',
    'nim_langserver',
})

-- local on_attach = require("plugins.configs.lspconfig").on_attach
-- local capabilities = require("plugins.configs.lspconfig").capabilities
--
-- local lspconfig = require "lspconfig"
--
-- -- bash
-- lspconfig.bashls.setup({
--   on_attach = on_attach,
--   capabilities = capabilities,
--   filetypes = {"sh"},
--   cmd = {"bash-language-server", "start"},
--   single_file_support = true
-- })
--
-- -- docker
-- lspconfig.dockerls.setup({
--   on_attach = on_attach,
--   capabilities = capabilities,
--   filetypes = {"dockerfile", "containerfile"},
--   cmd = {"docker-langserver", "--stdio"},
--   single_file_support = true,
--   --root_dir = vim.fs.dirname(vim.fs.find({'Containerfile', 'Dockerfile'}, { upward = true })[1]),
-- })
--
-- -- python
-- lspconfig.pyright.setup({
--   on_attach = on_attach,
--   capabilities = capabilities,
--   filetypes = {"python", "py"},
--   cmd = {"pyright-langserver", "--stdio"},
--   single_file_support = true
-- })
--
-- -- c 
-- lspconfig.clangd.setup({
--   on_attach = on_attach,
--   capabilities = capabilities,
--   filetypes = {"c", "cpp", "cc", "objc", "objcpp", "cuda", "proto"},
--   cmd = {"clangd"},
--   single_file_support = true
-- })
--
-- -- R 
-- lspconfig.r_language_server.setup({
--   on_attach = on_attach,
--   capabilities = capabilities,
--   filetypes = {"r", "rmd"},
--   cmd = {"R", "--slave", "-e", "languageserver::run()"},
--   single_file_support = true
-- })
--
-- -- Makefiles
-- lspconfig.autotools_ls.setup({
--     on_attach = on_attach,
--     capabilities = capabilities,
--     filetypes = {"config", "automake", "make", "Makefile", "configure.ac", "Makefile.am", "*.mk"},
--     cmd = {"autotools-language-server"},
--     single_file_support = true
-- })
--
-- -- perl
-- lspconfig.perlnavigator.setup({
--     on_attach = on_attach,
--     capabilities = capabilities,
--     filetypes = {"perl"},
--     cmd = {"perlnavigator"},
--     single_file_support = true
-- })
--
-- -- haskell 
-- lspconfig.hls.setup({
--     on_attach = on_attach,
--     capabilities = capabilities,
--     filetypes = {"haskell", "lhaskell"},
--     cmd = {"haskell-language-server-wrapper", "--lsp"},
--     single_file_support = true
-- })
--
-- -- nim
-- lspconfig.nim_langserver.setup({
--     on_attach = on_attach,
--     capabilities = capabilities,
--     filetypes = {"nim"},
--     cmd = {"nimlangserver", "--lsp"},
--     single_file_support = true
-- })
