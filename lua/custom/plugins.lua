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
            rocks = { "lua-utils", "magick" }
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
                                personal = "~/Documents/notes"
                            },
                            default_workspace = "personal",
                            index = "00_index.norg",
                        }
                    },
                    ["core.autocommands"] = {},
                    ["core.highlights"] = {},
                    ["core.integrations.treesitter"] = {},
                    ["core.presenter"] = {
                        config = {
                            zen_mode = "truezen"
                        }
                    },
                    ["core.export"] = {},
                    ["external.pandoc"] = {},
                    ["external.jupyter"] = {}
                }
            })
        end,
        dependencies = { "luarocks.nvim", "nvim-treesitter", "tamton-aquib/neorg-jupyter" }
    },
    {
        "champignoom/norg-pandoc",
        branch = "neorg-plugin",
        config = true,
    },
    {
        "NoahTheDuke/vim-just",
        ft = { "just" },
    },
    {
        "echasnovski/mini.animate",
        event = "VeryLazy",
        opts = function(_, opts)
            opts.scroll = {
                enable = false,
            }
        end,
    },

    {
        -- luarocks --local --lua-version=5.1 install magick
        "3rd/image.nvim",
        event = "VeryLazy",
        dependencies = {
            {
                "nvim-treesitter/nvim-treesitter",
                "luarocks.nvim",
                build = ":TSUpdate",
                config = function()
                    require("nvim-treesitter.configs").setup({
                        ensure_installed = { "markdown" },
                        highlight = { enable = true },
                    })
                end,
            },
        },
        opts = {
            backend = "kitty",
            processor = "magick_cli",
            integrations = {
                markdown = {
                enabled = true,
                clear_in_insert_mode = false,
                download_remote_images = true,
                only_render_image_at_cursor = false,
                filetypes = { "markdown", "vimwiki" }, -- markdown extensions (ie. quarto) can go here
                },
                neorg = {
                enabled = true,
                    clear_in_insert_mode = false,
                    download_remote_images = true,
                    only_render_image_at_cursor = false,
                    filetypes = { "norg" },
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = nil,
            max_height_window_percentage = 50,
            kitty_method = "normal",
            hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }
        },
    },
    {
        "Pocco81/true-zen.nvim"
    },
    {
        "itchyny/calendar.vim",
        lazy = false,
        config = function()
            -- vim.g.calendar_frame = 'default'
            vim.g.calendar_google_calendar = 0
            vim.g.calendar_cache_directory = "~/Documents/notes/.calendar"
        end
    },
    {
        "frankroeder/parrot.nvim",
        lazy = false,
        dependencies = { 'ibhagwan/fzf-lua', 'nvim-lua/plenary.nvim' },
        -- optionally include "rcarriga/nvim-notify" for beautiful notifications
        config = function()
            require("parrot").setup {
                -- Providers must be explicitly added to make them available.
                providers = {
                    pplx = {
                        api_key = os.getenv "PERPLEXITY_TOKEN",
                    },
                -- provide an empty list to make provider available (no API key required)
                -- ollama = {},
                },
                state_dir = os.getenv("HOME") .. "/Documents/notes/02_areas/ai/persisted",
                chat_dir = os.getenv("HOME") .. "/Documents/notes/02_areas/ai/chats",
            }
        end,
    }
}

return plugins
