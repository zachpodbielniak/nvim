local plugins = {
    {
        "neovim/nvim-lspconfig",
        config = function()
            require "plugins.configs.lspconfig"
            require "custom.configs.lspconfig"
        end,
    },
    {
        "ellisonleao/carbon-now.nvim",
        lazy = true,
        cmd = "CarbonNow",
        opts = {}
    },
    {
        "christoomey/vim-tmux-navigator",
        lazy = false,
    }
}

return plugins
