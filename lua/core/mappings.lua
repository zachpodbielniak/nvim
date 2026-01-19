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

    -- Run transclusion silently (show errors in tab) or run line
    ["<leader>tr"] = {
        function()
            local line = vim.api.nvim_get_current_line()

            -- Check for command transclusion: ![[!command]] or [title](!command)
            local cmd = line:match('!%[%[!(.-)%]%]')
            if not cmd then
                cmd = line:match('%[.-%]%(!(.-)%)')
            end

            if cmd then
                -- Run transclusion command silently
                local output = vim.fn.system(cmd)
                local exit_code = vim.v.shell_error

                if exit_code ~= 0 then
                    -- Error: open new tab with output and exit code
                    vim.cmd('tabnew')
                    local buf = vim.api.nvim_get_current_buf()
                    local lines = {}
                    table.insert(lines, '# Command Failed')
                    table.insert(lines, '')
                    table.insert(lines, '**Command**: `' .. cmd .. '`')
                    table.insert(lines, '**Exit Code**: ' .. exit_code)
                    table.insert(lines, '')
                    table.insert(lines, '## Output')
                    table.insert(lines, '')
                    -- Append command output
                    for _, l in ipairs(vim.split(output, '\n')) do
                        table.insert(lines, l)
                    end
                    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
                    vim.api.nvim_set_option_value('filetype', 'markdown', { buf = buf })
                    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
                    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
                else
                    -- Success: show brief notification
                    vim.notify('✓ ' .. cmd:match('^%S+'), vim.log.levels.INFO)
                end
            else
                -- No transclusion, fall back to run line behavior (Vyp!!bash<CR>)
                local keys = vim.api.nvim_replace_termcodes('Vyp!!bash<CR>', true, false, true)
                vim.api.nvim_feedkeys(keys, 'n', false)
            end
        end,
        "Run transclusion silently or run line"
    },

    -- Feed mappings 
    ["<leader>fu"] = { "<cmd>Feed update<CR>", "Update RSS Feeds"},
    ["<leader>fi"] = { "<cmd>Feed index<CR>", "Open RSS Feeds Inbox"},

    -- Inline transclusions (supports ![[path]], ![[!command]], [title](path), [title](!command), Transcription UUID)
    ["<leader>te"] = {
        function()
          local line = vim.api.nvim_get_current_line()

          -- Check for Transcription UUID: <uuid>
          local uuid = line:match('Transcription UUID:%s*([%x%-]+)')
          if uuid then
            local cmd = 'transcriptions view ' .. uuid .. ' -f simple'
            local output = vim.fn.systemlist(cmd)
            local row = vim.api.nvim_win_get_cursor(0)[1]
            vim.api.nvim_buf_set_lines(0, row, row, false, output)
            return
          end

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

          -- Check for Transcription UUID: <uuid>
          local uuid = line:match('Transcription UUID:%s*([%x%-]+)')
          if uuid then
            local cmd = 'transcriptions view ' .. uuid .. ' -f simple'
            local output = vim.fn.systemlist(cmd)
            open_float(output)
            return
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
        function() require('custom.vimban').regenerate_section() end,
        "vimban: regenerate section",
    },

    -- Go to link under cursor (supports ![[path]], ![[!command]], [title](path), [title](!command), Transcription UUID)
    ["<leader>tg"] = {
        function()
            local line = vim.fn.getline('.')
            local col = vim.fn.col('.')
            local notes_dir = vim.fn.expand('~/Documents/notes/')

            -- Check for Transcription UUID: <uuid>
            local uuid = line:match('Transcription UUID:%s*([%x%-]+)')
            if uuid then
                -- Execute transcriptions command, save to temp file, open in buffer
                local cmd = 'transcriptions view ' .. uuid .. ' -f simple'
                local output = vim.fn.system(cmd)
                local tmpfile = vim.fn.tempname() .. '.md'
                vim.fn.writefile(vim.split(output, '\n'), tmpfile)
                vim.cmd('edit ' .. tmpfile)
                return
            end

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
        function() require('custom.vimban').dashboard('daily') end,
        "vimban: dashboard",
    },

    -- Vimban: Dashboard picker (choose type)
    ["<leader>vD"] = {
        function() require('custom.vimban').dashboard_picker() end,
        "vimban: dashboard picker",
    },

    -- Vimban: FZF ticket picker
    ["<leader>vl"] = {
        function() require('custom.vimban').fzf_tickets('--mine') end,
        "vimban: fzf tickets",
    },

    -- Vimban: List with filter menu
    ["<leader>vL"] = {
        function() require('custom.vimban').list_filtered() end,
        "vimban: list filtered",
    },

    -- Vimban: kanban board floating window (interactive)
    ["<leader>vk"] = {
        function() require('custom.vimban').kanban_board() end,
        "vimban: kanban board",
    },

    -- Vimban: move current ticket status
    ["<leader>vm"] = {
        function() require('custom.vimban').move_status() end,
        "vimban: move ticket",
    },

    -- Vimban: add comment to current ticket
    ["<leader>vC"] = {
        function() require('custom.vimban').add_comment() end,
        "vimban: add comment",
    },

    -- Vimban: reply to comment on current ticket
    ["<leader>vr"] = {
        function() require('custom.vimban').reply_comment() end,
        "vimban: reply to comment",
    },

    -- Vimban: create ticket wizard
    ["<leader>vc"] = {
        function() require('custom.vimban').create_ticket() end,
        "vimban: create ticket",
    },

    -- Vimban: edit ticket fields
    ["<leader>ve"] = {
        function() require('custom.vimban').edit_ticket() end,
        "vimban: edit ticket",
    },

    -- Vimban: search tickets
    ["<leader>vs"] = {
        function() require('custom.vimban').search_tickets() end,
        "vimban: search tickets",
    },

    -- Vimban: people dashboard
    ["<leader>vp"] = {
        function() require('custom.vimban').people_dashboard() end,
        "vimban: people dashboard",
    },

    -- Vimban: insert transclusion link
    ["<leader>vi"] = {
        function() require('custom.vimban').insert_link() end,
        "vimban: insert link",
    },

    -- Vimban: view ticket under cursor in float
    ["<leader>vf"] = {
        function() require('custom.vimban').show_ticket_float() end,
        "vimban: show ticket float",
    },

    -- Vimban: go to ticket from transclusion
    ["<leader>vg"] = {
        function() require('custom.vimban').goto_ticket() end,
        "vimban: goto ticket",
    },

    -- Vimban: show help
    ["<leader>v?"] = {
        function() require('custom.vimban').show_help() end,
        "vimban: show help",
    },

    -- Shell: run commands and capture output
    ["<leader>ss"] = {
        function() require('custom.shell').prompt_command('split') end,
        "Shell: run command (split)",
    },
    ["<leader>sv"] = {
        function() require('custom.shell').prompt_command('vsplit') end,
        "Shell: run command (vsplit)",
    },
    ["<leader>sf"] = {
        function() require('custom.shell').prompt_command('float') end,
        "Shell: run command (float)",
    },
    ["<leader>st"] = {
        function() require('custom.shell').prompt_command('tab') end,
        "Shell: run command (tab)",
    },
    ["<leader>sb"] = {
        function() require('custom.shell').prompt_command('buffer') end,
        "Shell: run command (buffer)",
    },
    ["<leader>sh"] = {
        function() require('custom.shell').fzf_history() end,
        "Shell: history picker",
    },
    ["<leader>sr"] = {
        function() require('custom.shell').rerun() end,
        "Shell: re-run last command",
    },
    ["<leader>sR"] = {
        function() require('custom.shell').refresh_buffer() end,
        "Shell: refresh buffer",
    },
    ["<leader>s|"] = {
        function() require('custom.shell').prompt_filter() end,
        "Shell: filter output",
    },
    ["<leader>s?"] = {
        function() require('custom.shell').show_help() end,
        "Shell: show help",
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
        function() require('custom.vimban').create_from_selection() end,
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
