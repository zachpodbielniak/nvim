local on_attach = require("plugins.configs.lspconfig").on_attach
local capabilities = require("plugins.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"

-- bash
lspconfig.bashls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"sh"},
  cmd = {"bash-language-server", "start"},
  single_file_support = true
})

-- docker
lspconfig.dockerls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"dockerfile", "containerfile"},
  cmd = {"docker-langserver", "--stdio"},
  single_file_support = true,
  --root_dir = vim.fs.dirname(vim.fs.find({'Containerfile', 'Dockerfile'}, { upward = true })[1]),
})

-- python
lspconfig.pyright.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"python", "py"},
  cmd = {"pyright-langserver", "--stdio"},
  single_file_support = true
})

-- c 
lspconfig.clangd.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"c", "cpp", "cc", "objc", "objcpp", "cuda", "proto"},
  cmd = {"clangd"},
  single_file_support = true
})

-- R 
lspconfig.r_language_server.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = {"r", "rmd"},
  cmd = {"R", "--slave", "-e", "languageserver::run()"},
  single_file_support = true
})
