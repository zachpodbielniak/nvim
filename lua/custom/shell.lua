-- shell.lua - Run shell commands and capture output into scratch buffers
-- Enables staying in neovim for command output navigation, filtering, and re-running

local M = {}

-- Configuration
M.config = {
    history_file = vim.fn.stdpath('data') .. '/shell_history.txt',
    max_history = 100,
    default_destination = 'split',
    max_output_lines = 10000,
}

-- State
M.history = {}
M.last_command = nil
M.last_buffer = nil

-- ============================================================================
-- Core Helpers
-- ============================================================================

-- Calculate dynamic window size based on content
local function calc_float_size(content)
    local max_width = 0
    for _, line in ipairs(content) do
        max_width = math.max(max_width, #line)
    end
    -- Dynamic width: content width + padding, capped at 90% of screen
    local width = math.min(max_width + 4, math.floor(vim.o.columns * 0.9))
    width = math.max(width, 50)
    -- Dynamic height: content lines, capped at 85% of screen
    local height = math.min(#content, math.floor(vim.o.lines * 0.85))
    height = math.max(height, 5)
    return width, height
end

-- Open centered floating window with content
-- opts: { keymaps = {...}, filetype = 'text', on_close = fn, title = 'string' }
function M.open_float(content, opts)
    opts = opts or {}
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_set_option_value('filetype', opts.filetype or 'text', { buf = buf })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    vim.api.nvim_set_option_value('modifiable', opts.modifiable or false, { buf = buf })

    local width, height = calc_float_size(content)
    if opts.width then width = math.floor(vim.o.columns * opts.width) end
    if opts.height then height = math.floor(vim.o.lines * opts.height) end

    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local win_opts = {
        relative = 'editor',
        row = row,
        col = col,
        width = width,
        height = height,
        style = 'minimal',
        border = 'rounded',
    }
    if opts.title then
        win_opts.title = ' ' .. opts.title .. ' '
        win_opts.title_pos = 'center'
    end

    local win = vim.api.nvim_open_win(buf, true, win_opts)

    -- Close mappings
    local function close()
        if opts.on_close then opts.on_close() end
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
    end
    vim.keymap.set('n', 'q', close, { buffer = buf, silent = true })
    vim.keymap.set('n', '<Esc>', close, { buffer = buf, silent = true })

    -- Custom keymaps
    if opts.keymaps then
        for key, fn in pairs(opts.keymaps) do
            vim.keymap.set('n', key, function() fn(buf, win, close) end, { buffer = buf, silent = true })
        end
    end

    return buf, win
end

-- ============================================================================
-- History Management
-- ============================================================================

-- Load history from file
function M.load_history()
    local file = io.open(M.config.history_file, 'r')
    if file then
        M.history = {}
        for line in file:lines() do
            if line ~= '' then
                table.insert(M.history, line)
            end
        end
        file:close()
    end
end

-- Save history to file
function M.save_history()
    local file = io.open(M.config.history_file, 'w')
    if file then
        -- Keep only last max_history entries
        local start_idx = math.max(1, #M.history - M.config.max_history + 1)
        for i = start_idx, #M.history do
            file:write(M.history[i] .. '\n')
        end
        file:close()
    end
end

-- Add command to history (avoid duplicates at end)
function M.add_to_history(cmd)
    if cmd == '' then return end
    -- Remove duplicate if it exists at the end
    if #M.history > 0 and M.history[#M.history] == cmd then
        return
    end
    -- Remove any existing duplicate
    for i = #M.history, 1, -1 do
        if M.history[i] == cmd then
            table.remove(M.history, i)
            break
        end
    end
    table.insert(M.history, cmd)
    M.save_history()
end

-- ============================================================================
-- Filetype Detection
-- ============================================================================

-- Detect filetype from command or output
local function detect_filetype(cmd, output)
    -- Git commands
    if cmd:match('^git ') then
        if cmd:match('git diff') or cmd:match('git show') then
            return 'diff'
        elseif cmd:match('git log') then
            return 'git'
        end
        return 'git'
    end

    -- JSON detection
    if cmd:match('%.json') or cmd:match('jq') or cmd:match('yq.*-o.*json') then
        return 'json'
    end

    -- YAML detection
    if cmd:match('%.ya?ml') or cmd:match('yq') then
        return 'yaml'
    end

    -- Check output content for JSON/YAML
    if #output > 0 then
        local first_line = output[1] or ''
        if first_line:match('^%s*{') or first_line:match('^%s*%[') then
            return 'json'
        end
        if first_line:match('^%s*[-#]') or first_line:match('^%w+:') then
            return 'yaml'
        end
    end

    return 'text'
end

-- ============================================================================
-- Buffer Setup
-- ============================================================================

-- Setup scratch buffer for shell output
local function setup_scratch_buffer(buf, cmd, destination)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('swapfile', false, { buf = buf })
    vim.api.nvim_buf_set_var(buf, 'shell_command', cmd)
    vim.api.nvim_buf_set_var(buf, 'shell_destination', destination)

    -- Buffer-local keymaps
    local opts = { buffer = buf, silent = true }
    vim.keymap.set('n', 'r', function() M.refresh_buffer(buf) end, opts)
    vim.keymap.set('n', '|', function() M.prompt_filter(buf) end, opts)
    vim.keymap.set('n', 'q', function()
        vim.api.nvim_buf_delete(buf, { force = true })
    end, opts)
    vim.keymap.set('n', '?', function() M.show_help() end, opts)
end

-- ============================================================================
-- Core Execution
-- ============================================================================

-- Run command and capture output to buffer
function M.run_command(cmd, destination, opts)
    opts = opts or {}
    destination = destination or M.config.default_destination

    if not cmd or cmd == '' then
        vim.notify('No command provided', vim.log.levels.WARN)
        return
    end

    -- Add to history
    M.add_to_history(cmd)
    M.last_command = cmd

    -- Execute command
    local output = vim.fn.systemlist(cmd)
    local exit_code = vim.v.shell_error

    -- Handle empty output
    if #output == 0 or (#output == 1 and output[1] == '') then
        output = { '(No output)' }
    end

    -- Truncate large output
    if #output > M.config.max_output_lines then
        local truncated = {}
        for i = 1, M.config.max_output_lines do
            table.insert(truncated, output[i])
        end
        table.insert(truncated, '')
        table.insert(truncated, string.format('... truncated (%d lines total)', #output))
        output = truncated
    end

    -- Detect filetype
    local filetype = detect_filetype(cmd, output)

    -- Create buffer based on destination
    local buf, win

    if destination == 'float' then
        -- Add header info
        local content = {
            '$ ' .. cmd,
            string.rep('-', math.min(#cmd + 2, 80)),
        }
        for _, line in ipairs(output) do
            table.insert(content, line)
        end

        buf, win = M.open_float(content, {
            title = 'Shell Output (? for help)',
            filetype = filetype,
            width = 0.85,
            height = 0.8,
            keymaps = {
                ['r'] = function(b) M.refresh_buffer(b) end,
                ['|'] = function(b) M.prompt_filter(b) end,
            },
        })
        vim.api.nvim_buf_set_var(buf, 'shell_command', cmd)
        vim.api.nvim_buf_set_var(buf, 'shell_destination', destination)
    else
        -- Build content
        local content = {
            '$ ' .. cmd,
            string.rep('-', math.min(#cmd + 2, 80)),
        }
        for _, line in ipairs(output) do
            table.insert(content, line)
        end

        -- Open window first, then configure buffer
        if destination == 'split' then
            vim.cmd('new')
            win = vim.api.nvim_get_current_win()
            buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
            setup_scratch_buffer(buf, cmd, destination)
            vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
        elseif destination == 'vsplit' then
            vim.cmd('vnew')
            win = vim.api.nvim_get_current_win()
            buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
            setup_scratch_buffer(buf, cmd, destination)
            vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
        elseif destination == 'tab' then
            -- Write to temp file and use tabedit to avoid tab group issues
            local tmpfile = vim.fn.tempname()
            vim.fn.writefile(content, tmpfile)
            vim.cmd('tabedit ' .. tmpfile)
            win = vim.api.nvim_get_current_win()
            buf = vim.api.nvim_get_current_buf()
            setup_scratch_buffer(buf, cmd, destination)
            vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
        elseif destination == 'buffer' then
            -- New buffer in current window (for tabufline cycling)
            vim.cmd('enew')
            win = vim.api.nvim_get_current_win()
            buf = vim.api.nvim_get_current_buf()
            vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
            setup_scratch_buffer(buf, cmd, destination)
            vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
        end
    end

    M.last_buffer = buf

    -- Notify on non-zero exit
    if exit_code ~= 0 then
        vim.notify(string.format('Command exited with code %d', exit_code), vim.log.levels.WARN)
    end

    return buf, win
end

-- ============================================================================
-- User Interface Functions
-- ============================================================================

-- Prompt for command with vim.ui.input
function M.prompt_command(destination)
    destination = destination or M.config.default_destination
    vim.ui.input({
        prompt = 'Shell command: ',
        completion = 'shellcmd',
    }, function(cmd)
        if cmd and cmd ~= '' then
            M.run_command(cmd, destination)
        end
    end)
end

-- FZF history picker
function M.fzf_history(destination)
    destination = destination or M.config.default_destination

    if #M.history == 0 then
        vim.notify('No command history', vim.log.levels.INFO)
        return
    end

    -- Write history to temp file (reversed, most recent first)
    local tmpfile = vim.fn.tempname()
    local file = io.open(tmpfile, 'w')
    if file then
        for i = #M.history, 1, -1 do
            file:write(M.history[i] .. '\n')
        end
        file:close()
    end

    -- Run FZF with ctrl-e to edit
    local fzf_cmd = string.format(
        'cat %s | fzf --header "enter=run, ctrl-e=edit" --expect=ctrl-e --preview "echo {}"',
        tmpfile
    )
    local result = vim.fn.system(fzf_cmd)
    vim.fn.delete(tmpfile)

    local lines = vim.split(vim.fn.trim(result), '\n')
    if #lines < 1 then return end

    local key = lines[1]
    local cmd = #lines > 1 and lines[2] or lines[1]

    if not cmd or cmd == '' then return end

    if key == 'ctrl-e' then
        -- Edit before running
        vim.ui.input({
            prompt = 'Shell command: ',
            default = cmd,
            completion = 'shellcmd',
        }, function(edited_cmd)
            if edited_cmd and edited_cmd ~= '' then
                M.run_command(edited_cmd, destination)
            end
        end)
    else
        M.run_command(cmd, destination)
    end
end

-- Refresh buffer (re-run command)
function M.refresh_buffer(buf)
    buf = buf or vim.api.nvim_get_current_buf()

    local ok, cmd = pcall(vim.api.nvim_buf_get_var, buf, 'shell_command')
    if not ok or not cmd then
        vim.notify('No command associated with this buffer', vim.log.levels.WARN)
        return
    end

    local ok2, destination = pcall(vim.api.nvim_buf_get_var, buf, 'shell_destination')
    destination = ok2 and destination or 'split'

    -- Execute command
    local output = vim.fn.systemlist(cmd)
    local exit_code = vim.v.shell_error

    if #output == 0 or (#output == 1 and output[1] == '') then
        output = { '(No output)' }
    end

    -- Detect filetype
    local filetype = detect_filetype(cmd, output)

    -- Update buffer content
    local content = {
        '$ ' .. cmd,
        string.rep('-', math.min(#cmd + 2, 80)),
    }
    for _, line in ipairs(output) do
        table.insert(content, line)
    end

    vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })

    vim.notify('Refreshed', vim.log.levels.INFO)

    if exit_code ~= 0 then
        vim.notify(string.format('Command exited with code %d', exit_code), vim.log.levels.WARN)
    end
end

-- Re-run last command
function M.rerun()
    if not M.last_command then
        vim.notify('No previous command', vim.log.levels.WARN)
        return
    end
    M.run_command(M.last_command, M.config.default_destination)
end

-- ============================================================================
-- Filter Functions
-- ============================================================================

-- Filter presets
M.filter_presets = {
    { label = 'grep (pattern)', filter = 'grep' },
    { label = 'grep -v (exclude)', filter = 'grep -v' },
    { label = 'jq (JSON)', filter = 'jq' },
    { label = 'yq (YAML)', filter = 'yq' },
    { label = 'head', filter = 'head' },
    { label = 'tail', filter = 'tail' },
    { label = 'sort', filter = 'sort' },
    { label = 'sort -n', filter = 'sort -n' },
    { label = 'uniq', filter = 'uniq' },
    { label = 'wc -l', filter = 'wc -l' },
    { label = 'Custom...', filter = 'custom' },
}

-- Prompt for filter and apply
function M.prompt_filter(buf)
    buf = buf or vim.api.nvim_get_current_buf()

    local ok, cmd = pcall(vim.api.nvim_buf_get_var, buf, 'shell_command')
    if not ok or not cmd then
        vim.notify('No command associated with this buffer', vim.log.levels.WARN)
        return
    end

    local labels = {}
    for _, f in ipairs(M.filter_presets) do
        table.insert(labels, f.label)
    end

    vim.ui.select(labels, { prompt = 'Filter with:' }, function(choice)
        if not choice then return end

        for _, f in ipairs(M.filter_presets) do
            if f.label == choice then
                if f.filter == 'custom' then
                    vim.ui.input({ prompt = 'Filter command: ' }, function(custom)
                        if custom and custom ~= '' then
                            local new_cmd = cmd .. ' | ' .. custom
                            -- Get destination from current buffer
                            local ok2, destination = pcall(vim.api.nvim_buf_get_var, buf, 'shell_destination')
                            destination = ok2 and destination or 'split'
                            M.run_command(new_cmd, destination)
                        end
                    end)
                elseif f.filter == 'wc -l' then
                    -- No argument needed
                    local new_cmd = cmd .. ' | ' .. f.filter
                    local ok2, destination = pcall(vim.api.nvim_buf_get_var, buf, 'shell_destination')
                    destination = ok2 and destination or 'split'
                    M.run_command(new_cmd, destination)
                elseif f.filter == 'sort' or f.filter == 'sort -n' or f.filter == 'uniq' then
                    -- No argument needed
                    local new_cmd = cmd .. ' | ' .. f.filter
                    local ok2, destination = pcall(vim.api.nvim_buf_get_var, buf, 'shell_destination')
                    destination = ok2 and destination or 'split'
                    M.run_command(new_cmd, destination)
                else
                    -- Needs argument
                    local prompt_text = f.filter:match('^(%w+)') .. ' argument: '
                    vim.ui.input({ prompt = prompt_text }, function(arg)
                        if arg and arg ~= '' then
                            local new_cmd = cmd .. ' | ' .. f.filter .. ' ' .. vim.fn.shellescape(arg)
                            local ok2, destination = pcall(vim.api.nvim_buf_get_var, buf, 'shell_destination')
                            destination = ok2 and destination or 'split'
                            M.run_command(new_cmd, destination)
                        end
                    end)
                end
                return
            end
        end
    end)
end

-- ============================================================================
-- Help System
-- ============================================================================

-- Show shell keybinds help
function M.show_help()
    local help = {
        '# Shell Output Keybinds',
        '',
        '## Global Mappings (<leader>s)',
        '',
        '| Key | Description |',
        '|-----|-------------|',
        '| `<leader>ss` | Prompt for command (split) |',
        '| `<leader>sv` | Prompt for command (vsplit) |',
        '| `<leader>sf` | Prompt for command (float) |',
        '| `<leader>st` | Prompt for command (tab) |',
        '| `<leader>sb` | Prompt for command (buffer) |',
        '| `<leader>sh` | History picker (fzf) |',
        '| `<leader>sr` | Re-run last command |',
        '| `<leader>sR` | Refresh current buffer |',
        '| `<leader>s\\|` | Filter output |',
        '| `<leader>s?` | Show this help |',
        '',
        '## Buffer-Local Mappings (in shell output buffers)',
        '',
        '| Key | Action |',
        '|-----|--------|',
        '| `r` | Refresh (re-run command) |',
        '| `\\|` | Filter output |',
        '| `q` | Close buffer |',
        '| `?` | Show this help |',
        '',
        '## FZF History Keys',
        '',
        '| Key | Action |',
        '|-----|--------|',
        '| `enter` | Run selected command |',
        '| `ctrl-e` | Edit command before running |',
        '',
        '## Commands',
        '',
        '| Command | Description |',
        '|---------|-------------|',
        '| `:Sh [cmd]` | Run command (default: split) |',
        '| `:Shell [cmd]` | Alias for :Sh |',
        '| `:Shsplit [cmd]` | Run in horizontal split |',
        '| `:Shvsplit [cmd]` | Run in vertical split |',
        '| `:Shfloat [cmd]` | Run in floating window |',
        '| `:Shtab [cmd]` | Run in new tab |',
        '| `:Shbuffer [cmd]` | Run in new buffer (tabufline) |',
        '| `:Shhist` | FZF history picker |',
        '| `:Shrerun` | Re-run last command |',
        '| `:Shrefresh` | Refresh current buffer |',
        '| `:Shfilter` | Filter current buffer output |',
    }
    M.open_float(help, { title = 'Shell Help', width = 0.7, height = 0.85 })
end

-- ============================================================================
-- User Commands
-- ============================================================================

-- Setup user commands
function M.setup_commands()
    local new_cmd = vim.api.nvim_create_user_command

    new_cmd('Sh', function(opts)
        local cmd = opts.args
        if cmd == '' then
            M.prompt_command('split')
        else
            M.run_command(cmd, 'split')
        end
    end, { nargs = '*', complete = 'shellcmd', desc = 'Run shell command (split)' })

    new_cmd('Shell', function(opts)
        local cmd = opts.args
        if cmd == '' then
            M.prompt_command('split')
        else
            M.run_command(cmd, 'split')
        end
    end, { nargs = '*', complete = 'shellcmd', desc = 'Run shell command (split)' })

    new_cmd('Shsplit', function(opts)
        local cmd = opts.args
        if cmd == '' then
            M.prompt_command('split')
        else
            M.run_command(cmd, 'split')
        end
    end, { nargs = '*', complete = 'shellcmd', desc = 'Run shell command (horizontal split)' })

    new_cmd('Shvsplit', function(opts)
        local cmd = opts.args
        if cmd == '' then
            M.prompt_command('vsplit')
        else
            M.run_command(cmd, 'vsplit')
        end
    end, { nargs = '*', complete = 'shellcmd', desc = 'Run shell command (vertical split)' })

    new_cmd('Shfloat', function(opts)
        local cmd = opts.args
        if cmd == '' then
            M.prompt_command('float')
        else
            M.run_command(cmd, 'float')
        end
    end, { nargs = '*', complete = 'shellcmd', desc = 'Run shell command (float)' })

    new_cmd('Shtab', function(opts)
        local cmd = opts.args
        if cmd == '' then
            M.prompt_command('tab')
        else
            M.run_command(cmd, 'tab')
        end
    end, { nargs = '*', complete = 'shellcmd', desc = 'Run shell command (new tab)' })

    new_cmd('Shbuffer', function(opts)
        local cmd = opts.args
        if cmd == '' then
            M.prompt_command('buffer')
        else
            M.run_command(cmd, 'buffer')
        end
    end, { nargs = '*', complete = 'shellcmd', desc = 'Run shell command (new buffer)' })

    new_cmd('Shhist', function()
        M.fzf_history()
    end, { desc = 'Shell command history picker' })

    new_cmd('Shrerun', function()
        M.rerun()
    end, { desc = 'Re-run last shell command' })

    new_cmd('Shrefresh', function()
        M.refresh_buffer()
    end, { desc = 'Refresh current shell output buffer' })

    new_cmd('Shfilter', function()
        M.prompt_filter()
    end, { desc = 'Filter current shell output buffer' })
end

-- ============================================================================
-- Setup
-- ============================================================================

-- Initialize module
function M.setup()
    M.load_history()
    M.setup_commands()
end

return M
