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
    },
    {
        "xiyaowong/transparent.nvim",
        lazy = false,
        config = function()
            require("transparent").setup({
                -- table: default groups
                groups = {
                    'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
                    'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
                    'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
                    'SignColumn', 'CursorLine', 'CursorLineNr', 'StatusLine', 'StatusLineNC',
                    'EndOfBuffer',
                },
                -- table: additional groups that should be cleared
                extra_groups = {'NormalFloat', 'NvimTreeNormal', 'NvimTreeNormalNC'},
                -- table: groups you don't want to clear
                exclude_groups = {},
                -- function: code to be executed after highlight groups are cleared
                -- Also the user event "TransparentClear" will be triggered
                on_clear = function() end,
            })
            require('transparent').clear_prefix('BufferLine')
            require('transparent').clear_prefix('NeoTree')
            require('transparent').clear_prefix('lualine')
        end,
    },
    {
        "vhyrro/luarocks.nvim",
        priority = 1000, -- Very high priority is required, luarocks.nvim should run as the first plugin in your config.
        config = true,
        lazy = false,
        opts = {
            rocks = { "lua-utils" }
        },
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-neotest/nvim-nio",
            "nvim-neorg/lua-utils.nvim",
            "nvim-lua/plenary.nvim",
            "pysan3/pathlib.nvim"
        }
    },
    {
        "nvim-neorg/neorg",
        lazy = false, -- Disable lazy loading as some `lazy.nvim` distributions set `lazy = true` by default
        version = "*", -- Pin Neorg to the latest stable release
        build = ":Neorg sync-parsers",
        config = function()
            require("neorg").setup({
                load = {
                    ["core.defaults"] = {}, -- Loads default behavior 
                    ["core.concealer"] = {}, -- Adds pretty icons to documents
                    ["core.summary"] = {
                        config = {
                            strategy = "by_path"
                        }
                    },
                    ["core.dirman"] = { -- Manages Neorg WorkspaceSymbol
                        config = {
                            workspaces = {
                                personal = "~/Documents/notes/personal",
                                work = "~/Documents/notes/work"
                            },
                            default_workspace = "personal",
                            index = "00_index.norg",
                        }
                    }
                }
            })
        end,
        dependencies = { "luarocks.nvim", "nvim-treesitter" }
    }
}

return plugins
