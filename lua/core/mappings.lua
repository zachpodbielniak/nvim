-- n, v, i, t = mode names

local M = {}

M.general = {
  i = {
    -- go to  beginning and end
    ["<C-b>"] = { "<ESC>^i", "Beginning of line" },
    ["<C-e>"] = { "<End>", "End of line" },

    -- navigate within insert mode
    -- ["<C-h>"] = { "<Left>", "Move left" },
    -- ["<C-l>"] = { "<Right>", "Move right" },
    -- ["<C-j>"] = { "<Down>", "Move down" },
    -- ["<C-k>"] = { "<Up>", "Move up" },
    ["<C-h>"] = { "<Cmd>TmuxNavigateLeft<CR>", "Move left" },
    ["<C-l>"] = { "<Cmd>TmuxNavigateRight<CR>", "Move right" },
    ["<C-j>"] = { "<Cmd>TmuxNavigateDown<CR>", "Move down" },
    ["<C-k>"] = { "<Cmd>TmuxNavigateUp<CR>", "Move up" },
  },

  n = {
    ["<Esc>"] = { "<cmd> noh <CR>", "Clear highlights" },
    -- switch between windows
    -- ["<C-h>"] = { "<C-w>h", "Window left" },
    -- ["<C-l>"] = { "<C-w>l", "Window right" },
    -- ["<C-j>"] = { "<C-w>j", "Window down" },
    -- ["<C-k>"] = { "<C-w>k", "Window up" },
    ["<C-h>"] = { "<Cmd>TmuxNavigateLeft<CR>", "Move left" },
    ["<C-l>"] = { "<Cmd>TmuxNavigateRight<CR>", "Move right" },
    ["<C-j>"] = { "<Cmd>TmuxNavigateDown<CR>", "Move down" },
    ["<C-k>"] = { "<Cmd>TmuxNavigateUp<CR>", "Move up" },

    -- save
    ["<C-s>"] = { "<cmd> w <CR>", "Save file" },

    -- Copy all
    ["<C-c>"] = { "<cmd> %y+ <CR>", "Copy whole file" },

    -- Paste and keep register
    ["<leader>p"] = { "\"_dP", "Paste and safe buffer"},

    -- line numbers
    ["<leader>n"] = { "<cmd> set nu! <CR>", "Toggle line number" },
    ["<leader>rn"] = { "<cmd> set rnu! <CR>", "Toggle relative number" },

    -- Allow moving the cursor through wrapped lines with j, k, <Up> and <Down>
    -- http://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk/
    -- empty mode is same as using <cmd> :map
    -- also don't use g[j|k] when in operator pending mode, so it doesn't alter d, y or c behaviour
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },

    -- new buffer
    ["<leader>b"] = { "<cmd> enew <CR>", "New buffer" },
    ["<leader>ch"] = { "<cmd> NvCheatsheet <CR>", "Mapping cheatsheet" },

    ["<leader>fm"] = {
      function()
        vim.lsp.buf.format { async = true }
      end,
      "LSP formatting",
    },

    -- Neorg Settings 
    ["<leader>oi"] = { "<cmd>Neorg index<CR>", "Neorg Index"},
    ["<leader>or"] = {"<cmd>Neorg return<CR>", "Neorg Return"},
    ["<leader>om"] = {"<cmd>Neorg inject-metadata<CR>", "Neorg Inject Metadata"},
    ["<leader>ot"] = {"<cmd>Neorg toc<CR>", "Neorg TOC"},

    -- Zenmode
    ["<leader>zn"] = { "<cmd>TZNarrow<CR>", "Zenmode Narrow"},
    ["<leader>zf"] = { "<cmd>TZFocus<CR>", "Zenmode Focus"},
    ["<leader>zm"] = { "<cmd>TZMinimalist<CR>", "Zenmode Minimalist"},
    ["<leader>za"] = { "<cmd>TZAtaraxis<CR>", "Zenmode Ataraxis"},

    -- Calendar 
    ["<leader>cc"] = { "<cmd>Calendar<CR>", "Calendar"},
    ["<leader>cC"] = { "<cmd>Calendar -view=clock<CR>", "Clock"},
    ["<leader>cw"] = { "<cmd>Calendar -view=week<CR>", "Calendar (Week)"},
    ["<leader>cd"] = { "<cmd>Calendar -view=day<CR>", "Calendar (Day)"},
    ["<leader>cD"] = { "<cmd>Calendar -view=days<CR>", "Calendar (Days)"},
    ["<leader>cy"] = { "<cmd>Calendar -view=year<CR>", "Calendar (Year)"},

    -- Parrot running 
    ["<leader>an"] = { "<cmd>PrtChatNew<CR>", "New AI Chat"},
    ["<leader>at"] = { "<cmd>PrtChatToggle<CR>", "Toggle AI Chat"},
    ["<leader>ar"] = { "<cmd>PrtChatRespond<CR>", "AI Chat Respond"},
    ["<leader>as"] = { "<cmd>PrtChatStop<CR>", "AI Chat Stop Responding"},
    ["<leader>af"] = { "<cmd>PrtChatFinder<CR>", "AI Chat Find"},
    ["<leader>am"] = { "<cmd>PrtModel<CR>", "AI Model Selector"},
    ["<leader>ap"] = { "<cmd>PrtProvider<CR>", "AI Provider Selector"},

    ["<leader>tt"] = { "<cmd>terminal<CR><cmd>SendHere<CR>", "Open Terminal"},
    ["<leader>tr"] = { "Vyp!!bash<CR>", "Run Line"},

    -- Feed mappings 
    ["<leader>fu"] = { "<cmd>Feed update<CR>", "Update RSS Feeds"},
    ["<leader>fi"] = { "<cmd>Feed index<CR>", "Open RSS Feeds Inbox"},

    -- Inline transclusions (supports ![[path]], ![[!command]], [title](path), [title](!command))
    ["<leader>te"] = {
        function()
          local line = vim.api.nvim_get_current_line()

          -- Check for command transclusion: ![[!command]] or [title](!command)
          local cmd = line:match('!%[%[!(.-)%]%]')
          if not cmd then
            cmd = line:match('%[.-%]%(!(.-)%)')
          end
          if cmd then
            local output = vim.fn.systemlist(cmd)
            local row = vim.api.nvim_win_get_cursor(0)[1]
            vim.api.nvim_buf_set_lines(0, row, row, false, output)
            return
          end

          -- Try file transclusion format first, then markdown link
          local path = line:match('!%[%[(.-)%]%]')
          if not path then
            path = line:match('%[.-%]%((.-)%)')
            -- Skip URLs
            if path and path:match('^https?://') then path = nil end
          end
          if path then
            local full_path = vim.fn.expand('~/Documents/notes/' .. path)
            if vim.fn.filereadable(full_path) == 1 then
              local content = vim.fn.readfile(full_path)
              local row = vim.api.nvim_win_get_cursor(0)[1]
              vim.api.nvim_buf_set_lines(0, row, row, false, content)
            end
          end
        end,
        "expand link or run command inline"
    },
    ["<leader>tf"] = {
        function()
          local line = vim.api.nvim_get_current_line()

          -- Helper to calculate dynamic window size
          local function calc_float_size(content)
            -- Find max line width
            local max_width = 0
            for _, l in ipairs(content) do
              max_width = math.max(max_width, #l)
            end
            -- Dynamic width: content width + padding, capped at 85% of screen
            local width = math.min(max_width + 4, math.floor(vim.o.columns * 0.85))
            width = math.max(width, 40)  -- minimum width
            -- Dynamic height: content lines, capped at 80% of screen
            local height = math.min(#content, math.floor(vim.o.lines * 0.8))
            height = math.max(height, 3)  -- minimum height
            return width, height
          end

          -- Helper to open centered floating window
          local function open_float(content)
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
            vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
            local width, height = calc_float_size(content)
            -- Center in editor
            local row = math.floor((vim.o.lines - height) / 2)
            local col = math.floor((vim.o.columns - width) / 2)
            vim.api.nvim_open_win(buf, true, {
              relative = 'editor',
              row = row, col = col,
              width = width, height = height,
              style = 'minimal',
              border = 'rounded',
            })
            vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf, silent = true })
          end

          -- Check for command transclusion: ![[!command]] or [title](!command)
          local cmd = line:match('!%[%[!(.-)%]%]')
          if not cmd then
            cmd = line:match('%[.-%]%(!(.-)%)')
          end
          if cmd then
            local output = vim.fn.systemlist(cmd)
            open_float(output)
            return
          end

          -- Try file transclusion format first, then markdown link
          local path = line:match('!%[%[(.-)%]%]')
          if not path then
            path = line:match('%[.-%]%((.-)%)')
            -- Skip URLs
            if path and path:match('^https?://') then path = nil end
          end
          if path then
            local full_path = vim.fn.expand('~/Documents/notes/' .. path)
            if vim.fn.filereadable(full_path) == 1 then
              local content = vim.fn.readfile(full_path)
              open_float(content)
            end
          end
        end,
        "open link or run command in floating window"
    },

    -- Vimban: regenerate VIMBAN section under cursor
    ["<leader>vR"] = {
        function()
            local start_line = vim.fn.search('VIMBAN:[A-Z_]*:START', 'bnW')
            local end_line = vim.fn.search('VIMBAN:[A-Z_]*:END', 'nW')
            if start_line > 0 and end_line > 0 then
                local marker = vim.fn.getline(start_line)
                local section = marker:match('VIMBAN:(%w+):START')
                local file = vim.fn.expand('%:p')
                local rel = file:gsub(vim.fn.expand('~/Documents/notes/'), '')
                vim.cmd(string.format('%d,%d!vimban dashboard --section %s --person "![[%s]]"',
                    start_line, end_line, section:lower(), rel))
            end
        end,
        "vimban: regenerate section",
    },

    -- Go to link under cursor (supports ![[path]], ![[!command]], [title](path), [title](!command))
    ["<leader>tg"] = {
        function()
            local line = vim.fn.getline('.')
            local col = vim.fn.col('.')
            local notes_dir = vim.fn.expand('~/Documents/notes/')

            -- Check command transclusion links: ![[!command]]
            for s, cmd, e in line:gmatch('()!%[%[!([^%]]+)%]%]()') do
                if col >= s and col <= e then
                    -- Execute command, save to temp file, open in buffer
                    local output = vim.fn.system(cmd)
                    local tmpfile = vim.fn.tempname() .. '.md'
                    vim.fn.writefile(vim.split(output, '\n'), tmpfile)
                    vim.cmd('edit ' .. tmpfile)
                    return
                end
            end

            -- Check markdown command links: [title](!command)
            for s, _, cmd, e in line:gmatch('()%[([^%]]+)%]%((!.-)%)()') do
                if col >= s and col <= e then
                    -- Remove leading ! from command
                    cmd = cmd:sub(2)
                    local output = vim.fn.system(cmd)
                    local tmpfile = vim.fn.tempname() .. '.md'
                    vim.fn.writefile(vim.split(output, '\n'), tmpfile)
                    vim.cmd('edit ' .. tmpfile)
                    return
                end
            end

            -- Check file transclusion links: ![[path]]
            for s, path, e in line:gmatch('()!%[%[([^%]]+)%]%]()') do
                if col >= s and col <= e then
                    local full = notes_dir .. path
                    if vim.fn.filereadable(full) == 1 then
                        vim.cmd('edit ' .. full)
                    end
                    return
                end
            end

            -- Check markdown links: [title](path)
            for s, _, path, e in line:gmatch('()%[([^%]]+)%]%(([^%)]+)%)()') do
                if col >= s and col <= e then
                    -- Skip URLs and commands (already handled above)
                    if path:match('^https?://') then return end
                    if path:match('^!') then return end
                    local full = notes_dir .. path
                    if vim.fn.filereadable(full) == 1 then
                        vim.cmd('edit ' .. full)
                    end
                    return
                end
            end
        end,
        "go to link or run command under cursor",
    },

    -- Vimban: daily dashboard floating window
    ["<leader>vd"] = {
        function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false,
                vim.fn.systemlist('vimban dashboard daily'))
            vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
            local w = math.floor(vim.o.columns * 0.8)
            local h = math.floor(vim.o.lines * 0.8)
            vim.api.nvim_open_win(buf, true, {
                relative = 'editor', width = w, height = h,
                col = (vim.o.columns - w) / 2, row = (vim.o.lines - h) / 2,
                style = 'minimal', border = 'rounded',
            })
            vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf })
        end,
        "vimban: dashboard",
    },

    -- Vimban: FZF ticket picker
    ["<leader>vl"] = {
        function()
            local result = vim.fn.system(
                'vimban list --mine -f plain --no-header | fzf --preview "vimban show {1} -f md"')
            local id = vim.fn.trim(result):match('^%S+')
            if id and id ~= '' then
                vim.cmd('vsplit | terminal vimban show ' .. id)
            end
        end,
        "vimban: fzf tickets",
    },

    -- Vimban: kanban board floating window
    ["<leader>vk"] = {
        function()
            local buf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_buf_set_lines(buf, 0, -1, false,
                vim.fn.systemlist('vimban kanban -f md --mine'))
            vim.api.nvim_buf_set_option(buf, 'filetype', 'markdown')
            local w = math.floor(vim.o.columns * 0.9)
            local h = math.floor(vim.o.lines * 0.8)
            vim.api.nvim_open_win(buf, true, {
                relative = 'editor', width = w, height = h,
                col = (vim.o.columns - w) / 2, row = (vim.o.lines - h) / 2,
                style = 'minimal', border = 'rounded',
            })
            vim.keymap.set('n', 'q', ':close<CR>', { buffer = buf })
        end,
        "vimban: kanban board",
    },

    -- Vimban: move current ticket status
    ["<leader>vm"] = {
        function()
            local id = nil
            for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, 20, false)) do
                id = line:match('^id:%s*"?([^"]+)"?')
                if id then break end
            end
            if not id then return end
            vim.ui.select(
                {'ready', 'in_progress', 'blocked', 'review', 'done'},
                { prompt = 'Status:' },
                function(s)
                    if s then
                        vim.fn.system('vimban move ' .. id .. ' ' .. s)
                        vim.cmd('edit!')
                    end
                end
            )
        end,
        "vimban: move ticket",
    },

    -- Vimban: add comment to current ticket
    ["<leader>vC"] = {
        function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
            local ticket_id = nil
            for _, line in ipairs(lines) do
                local id = line:match('^id:%s*"?([^"]+)"?')
                if id then
                    ticket_id = id
                    break
                end
            end
            if not ticket_id then
                vim.notify("No ticket ID found in frontmatter", vim.log.levels.WARN)
                return
            end
            vim.ui.input({ prompt = "Comment: " }, function(input)
                if input and input ~= "" then
                    local cmd = string.format("vimban comment %s %q", ticket_id, input)
                    local result = vim.fn.system(cmd)
                    vim.notify(result, vim.log.levels.INFO)
                    vim.cmd("edit!")
                end
            end)
        end,
        "vimban: add comment",
    },

    -- Vimban: reply to comment on current ticket
    ["<leader>vr"] = {
        function()
            local lines = vim.api.nvim_buf_get_lines(0, 0, 50, false)
            local ticket_id = nil
            for _, line in ipairs(lines) do
                local id = line:match('^id:%s*"?([^"]+)"?')
                if id then
                    ticket_id = id
                    break
                end
            end
            if not ticket_id then
                vim.notify("No ticket ID found in frontmatter", vim.log.levels.WARN)
                return
            end
            vim.ui.input({ prompt = "Reply to comment #: " }, function(reply_to)
                if reply_to and reply_to ~= "" then
                    vim.ui.input({ prompt = "Reply: " }, function(input)
                        if input and input ~= "" then
                            local cmd = string.format("vimban comment %s %q --reply-to %s", ticket_id, input, reply_to)
                            local result = vim.fn.system(cmd)
                            vim.notify(result, vim.log.levels.INFO)
                            vim.cmd("edit!")
                        end
                    end)
                end
            end)
        end,
        "vimban: reply to comment",
    },

  },

  t = {
    -- ["<esc>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
    ["<C-x>"] = { vim.api.nvim_replace_termcodes("<C-\\><C-N>", true, true, true), "Escape terminal mode" },
    
    -- send esc to child application
    -- ["<C-x>"] = { function() vim.api.nvim_feedkeys("\x1b", "t", false) end, "Send <Esc> to terminal app" },
    ["<C-h>"] = { "<Cmd>TmuxNavigateLeft<CR>", "Move left" },
    ["<C-l>"] = { "<Cmd>TmuxNavigateRight<CR>", "Move right" },
    ["<C-j>"] = { "<Cmd>TmuxNavigateDown<CR>", "Move down" },
    ["<C-k>"] = { "<Cmd>TmuxNavigateUp<CR>", "Move up" },
  },
    -- ["<C-<esc>>"] = { vim.fn.term_sendkeys(0, "\27").."<CR>"), "Send <ESC> to terminal"}
   -- vim.keymap.set('t', '<C-E>', [[<C-\><C-N>:lua vim.api.nvim_buf_call(0, function() vim.fn.term_sendkeys(0, "\27") end)<CR>i]], { noremap = true, silent = true })

  v = {
    ["<Up>"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    ["<Down>"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["<"] = { "<gv", "Indent line" },
    [">"] = { ">gv", "Indent line" },

    -- Zenmode
    ["<leader>zn"] = { "<cmd>TZNarrow<CR>", "Zenmode Narrow"},
    ["<leader>zf"] = { "<cmd>TZFocus<CR>", "Zenmode Focus"},
    ["<leader>zm"] = { "<cmd>TZMinimalist<CR>", "Zenmode Minimalist"},
    ["<leader>za"] = { "<cmd>TZAtaraxis<CR>", "Zenmode Ataraxis"},


    -- ai chat
    ["<leader>ai"] = { "<cmd>PrtImplement<CR>", "AI Implement Highlighted"},
    ["<leader>aa"] = { "<cmd>PrtAsk<CR>", "AI Ask Highlighted"},

    -- neorg
    ["ft"] = { "!column -t -s '|' -o '|'<CR>", "Format Table"},

    -- Vimban: create ticket from selection
    ["<leader>vc"] = {
        function()
            local lines = vim.fn.getline("'<", "'>")
            local title = table.concat(lines, ' ')
            vim.ui.select({'task', 'bug', 'story', 'research'}, { prompt = 'Type:' },
                function(t)
                    if t then vim.fn.system(string.format('vimban create %s "%s"', t, title)) end
                end
            )
        end,
        "vimban: create from selection",
    },
  },

  x = {
    ["j"] = { 'v:count || mode(1)[0:1] == "no" ? "j" : "gj"', "Move down", opts = { expr = true } },
    ["k"] = { 'v:count || mode(1)[0:1] == "no" ? "k" : "gk"', "Move up", opts = { expr = true } },
    -- Don't copy the replaced text after pasting in visual mode
    -- https://vim.fandom.com/wiki/Replace_a_word_with_yanked_text#Alternative_mapping_for_paste
    ["p"] = { 'p:let @+=@0<CR>:let @"=@0<CR>', "Dont copy replaced text", opts = { silent = true } },

  },
}

M.tabufline = {
  plugin = true,

  n = {
    -- cycle through buffers
    ["<tab>"] = {
      function()
        require("nvchad.tabufline").tabuflineNext()
      end,
      "Goto next buffer",
    },

    ["<S-tab>"] = {
      function()
        require("nvchad.tabufline").tabuflinePrev()
      end,
      "Goto prev buffer",
    },

    -- close buffer + hide terminal buffer
    ["<leader>x"] = {
      function()
        require("nvchad.tabufline").close_buffer()
      end,
      "Close buffer",
    },
  },
}

M.comment = {
  plugin = true,

  -- toggle comment in both modes
  n = {
    ["<leader>/"] = {
      function()
        require("Comment.api").toggle.linewise.current()
      end,
      "Toggle comment",
    },
  },

  v = {
    ["<leader>/"] = {
      "<ESC><cmd>lua require('Comment.api').toggle.linewise(vim.fn.visualmode())<CR>",
      "Toggle comment",
    },
  },
}

M.lspconfig = {
  plugin = true,

  -- See `<cmd> :help vim.lsp.*` for documentation on any of the below functions

  n = {
    ["gD"] = {
      function()
        vim.lsp.buf.declaration()
      end,
      "LSP declaration",
    },

    ["gd"] = {
      function()
        vim.lsp.buf.definition()
      end,
      "LSP definition",
    },

    ["K"] = {
      function()
        vim.lsp.buf.hover()
      end,
      "LSP hover",
    },

    ["gi"] = {
      function()
        vim.lsp.buf.implementation()
      end,
      "LSP implementation",
    },

    ["<leader>ls"] = {
      function()
        vim.lsp.buf.signature_help()
      end,
      "LSP signature help",
    },

    ["<leader>D"] = {
      function()
        vim.lsp.buf.type_definition()
      end,
      "LSP definition type",
    },

    ["<leader>ra"] = {
      function()
        require("nvchad.renamer").open()
      end,
      "LSP rename",
    },

    ["<leader>ca"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "LSP code action",
    },

    ["gr"] = {
      function()
        vim.lsp.buf.references()
      end,
      "LSP references",
    },

    ["<leader>lf"] = {
      function()
        vim.diagnostic.open_float { border = "rounded" }
      end,
      "Floating diagnostic",
    },

    ["[d"] = {
      function()
        vim.diagnostic.goto_prev { float = { border = "rounded" } }
      end,
      "Goto prev",
    },

    ["]d"] = {
      function()
        vim.diagnostic.goto_next { float = { border = "rounded" } }
      end,
      "Goto next",
    },

    ["<leader>q"] = {
      function()
        vim.diagnostic.setloclist()
      end,
      "Diagnostic setloclist",
    },

    ["<leader>wa"] = {
      function()
        vim.lsp.buf.add_workspace_folder()
      end,
      "Add workspace folder",
    },

    ["<leader>wr"] = {
      function()
        vim.lsp.buf.remove_workspace_folder()
      end,
      "Remove workspace folder",
    },

    ["<leader>wl"] = {
      function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end,
      "List workspace folders",
    },
  },

  v = {
    ["<leader>ca"] = {
      function()
        vim.lsp.buf.code_action()
      end,
      "LSP code action",
    },
  },
}

M.nvimtree = {
  plugin = true,

  n = {
    -- toggle
    ["<C-n>"] = { "<cmd> NvimTreeToggle <CR>", "Toggle nvimtree" },

    -- focus
    ["<leader>e"] = { "<cmd> NvimTreeFocus <CR>", "Focus nvimtree" },
  },
}

M.telescope = {
  plugin = true,

  n = {
    -- find
    ["<leader>ff"] = { "<cmd> Telescope find_files <CR>", "Find files" },
    -- ["<leader>fa"] = { "<cmd> Telescope find_files follow=true no_ignore=true hidden=true <CR>", "Find all" },
    ["<leader>fa"] = { "<cmd> Telescope find_files find_command=rg,--ignore,--hidden,--files <CR>", "Find all" },
    ["<leader>fw"] = { "<cmd> Telescope live_grep <CR>", "Live grep" },
    ["<leader>fb"] = { "<cmd> Telescope buffers <CR>", "Find buffers" },
    ["<leader>fh"] = { "<cmd> Telescope help_tags <CR>", "Help page" },
    ["<leader>fo"] = { "<cmd> Telescope oldfiles <CR>", "Find oldfiles" },
    ["<leader>fz"] = { "<cmd> Telescope current_buffer_fuzzy_find <CR>", "Find in current buffer" },

    -- git
    ["<leader>cm"] = { "<cmd> Telescope git_commits <CR>", "Git commits" },
    ["<leader>gt"] = { "<cmd> Telescope git_status <CR>", "Git status" },

    -- pick a hidden term
    ["<leader>pt"] = { "<cmd> Telescope terms <CR>", "Pick hidden term" },

    -- theme switcher
    ["<leader>th"] = { "<cmd> Telescope themes <CR>", "Nvchad themes" },

    ["<leader>ma"] = { "<cmd> Telescope marks <CR>", "telescope bookmarks" },
  },
}

M.nvterm = {
  plugin = true,

  t = {
    -- toggle in terminal mode
    ["<A-i>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "Toggle floating term",
    },

    ["<A-h>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    ["<A-v>"] = {
      function()
        require("nvterm.terminal").toggle "vertical"
      end,
      "Toggle vertical term",
    },
  },

  n = {
    -- toggle in normal mode
    ["<A-i>"] = {
      function()
        require("nvterm.terminal").toggle "float"
      end,
      "Toggle floating term",
    },

    ["<A-h>"] = {
      function()
        require("nvterm.terminal").toggle "horizontal"
      end,
      "Toggle horizontal term",
    },

    ["<A-v>"] = {
      function()
        require("nvterm.terminal").toggle "vertical"
      end,
      "Toggle vertical term",
    },

    -- new
    ["<leader>h"] = {
      function()
        require("nvterm.terminal").new "horizontal"
      end,
      "New horizontal term",
    },

    ["<leader>tv"] = {
      function()
        require("nvterm.terminal").new "vertical"
      end,
      "New vertical term",
    },
  },
}

M.whichkey = {
  plugin = true,

  n = {
    ["<leader>wK"] = {
      function()
        vim.cmd "WhichKey"
      end,
      "Which-key all keymaps",
    },
    ["<leader>wk"] = {
      function()
        local input = vim.fn.input "WhichKey: "
        vim.cmd("WhichKey " .. input)
      end,
      "Which-key query lookup",
    },
  },
}

M.blankline = {
  plugin = true,

  n = {
    ["<leader>cc"] = {
      function()
        local ok, start = require("indent_blankline.utils").get_current_context(
          vim.g.indent_blankline_context_patterns,
          vim.g.indent_blankline_use_treesitter_scope
        )

        if ok then
          vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { start, 0 })
          vim.cmd [[normal! _]]
        end
      end,

      "Jump to current context",
    },
  },
}

M.gitsigns = {
  plugin = true,

  n = {
    -- Navigation through hunks
    ["]c"] = {
      function()
        if vim.wo.diff then
          return "]c"
        end
        vim.schedule(function()
          require("gitsigns").next_hunk()
        end)
        return "<Ignore>"
      end,
      "Jump to next hunk",
      opts = { expr = true },
    },

    ["[c"] = {
      function()
        if vim.wo.diff then
          return "[c"
        end
        vim.schedule(function()
          require("gitsigns").prev_hunk()
        end)
        return "<Ignore>"
      end,
      "Jump to prev hunk",
      opts = { expr = true },
    },

    -- Actions
    ["<leader>rh"] = {
      function()
        require("gitsigns").reset_hunk()
      end,
      "Reset hunk",
    },

    ["<leader>ph"] = {
      function()
        require("gitsigns").preview_hunk()
      end,
      "Preview hunk",
    },

    ["<leader>gb"] = {
      function()
        package.loaded.gitsigns.blame_line()
      end,
      "Blame line",
    },

    ["<leader>td"] = {
      function()
        require("gitsigns").toggle_deleted()
      end,
      "Toggle deleted",
    },
  },
}

return M
