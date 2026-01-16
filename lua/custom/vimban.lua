-- vimban.lua - Comprehensive Neovim interface for vimban ticket management
-- Extends <leader>v namespace with ticket viewing, creating, and updating

local M = {}

-- Configuration
M.config = {
    notes_dir = vim.fn.expand('~/Documents/notes/'),
    statuses = { 'backlog', 'ready', 'in_progress', 'blocked', 'review', 'delegated', 'done', 'cancelled' },
    ticket_types = { 'task', 'bug', 'story', 'research', 'epic', 'sub-task' },
    priorities = { 'critical', 'high', 'medium', 'low' },
    dashboard_types = { 'daily', 'weekly', 'sprint', 'project', 'person' },
}

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
-- opts: { keymaps = {...}, filetype = 'markdown', on_close = fn, title = 'string' }
function M.open_float(content, opts)
    opts = opts or {}
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
    vim.api.nvim_set_option_value('filetype', opts.filetype or 'markdown', { buf = buf })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
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
        vim.api.nvim_win_close(win, true)
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

-- Detect ticket ID from context
-- 1. Check frontmatter (id: field)
-- 2. Check cursor line for transclusion ![[path]]
-- 3. Check cursor line for ticket ID pattern (PROJ-XXXXX)
function M.get_ticket_id()
    -- First, check frontmatter
    local lines = vim.api.nvim_buf_get_lines(0, 0, 30, false)
    for _, line in ipairs(lines) do
        local id = line:match('^id:%s*"?([^"]+)"?')
        if id then return id end
    end

    -- Check cursor line for transclusion
    local cursor_line = vim.api.nvim_get_current_line()
    local path = cursor_line:match('!%[%[([^%]]+)%]%]')
    if path then
        -- Extract ticket ID from path
        local id = path:match('([A-Z]+-[0-9]+)')
        if id then return id end
        -- If path is a full file path, try to read the file
        local full_path = M.config.notes_dir .. path
        if vim.fn.filereadable(full_path) == 1 then
            local file_lines = vim.fn.readfile(full_path, '', 30)
            for _, line in ipairs(file_lines) do
                id = line:match('^id:%s*"?([^"]+)"?')
                if id then return id end
            end
        end
    end

    -- Check for ticket ID pattern in cursor line
    local id = cursor_line:match('([A-Z]+-[0-9]+)')
    if id then return id end

    return nil
end

-- Get ticket file path from ID using JSON output
-- Returns the relative path to the ticket file
function M.get_ticket_filepath(ticket_id)
    local json_str = vim.fn.system('vimban -f json show ' .. ticket_id .. ' 2>/dev/null')
    local ok, data = pcall(vim.fn.json_decode, json_str)
    if ok and data and data.filepath then
        return data.filepath
    end
    return nil
end

-- Get ticket path from ID (legacy wrapper)
function M.get_ticket_path(ticket_id)
    return M.get_ticket_filepath(ticket_id)
end

-- ============================================================================
-- Dashboard Functions
-- ============================================================================

-- Open daily dashboard in floating window
function M.dashboard(dashboard_type)
    dashboard_type = dashboard_type or 'daily'
    local content = vim.fn.systemlist('vimban -f md dashboard ' .. dashboard_type)
    M.open_float(content, {
        title = 'Vimban Dashboard (' .. dashboard_type .. ')',
        width = 0.85,
        height = 0.85,
    })
end

-- Dashboard type picker
function M.dashboard_picker()
    vim.ui.select(M.config.dashboard_types, { prompt = 'Dashboard type:' }, function(dtype)
        if not dtype then return end
        if dtype == 'project' then
            vim.ui.input({ prompt = 'Project:' }, function(project)
                if project and project ~= '' then
                    local content = vim.fn.systemlist('vimban -f md dashboard project --project ' .. project)
                    M.open_float(content, { title = 'Project: ' .. project, width = 0.85, height = 0.85 })
                end
            end)
        elseif dtype == 'person' then
            vim.ui.input({ prompt = 'Person:' }, function(person)
                if person and person ~= '' then
                    local content = vim.fn.systemlist('vimban -f md dashboard person --person "' .. person .. '"')
                    M.open_float(content, { title = 'Person: ' .. person, width = 0.85, height = 0.85 })
                end
            end)
        else
            M.dashboard(dtype)
        end
    end)
end

-- ============================================================================
-- Kanban Functions
-- ============================================================================

-- Interactive kanban board with actions
function M.kanban_board()
    local function refresh_kanban(buf)
        local content = vim.fn.systemlist('vimban -f md kanban --mine')
        vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
        vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
    end

    local function get_ticket_under_cursor()
        local line = vim.api.nvim_get_current_line()
        -- Match ticket ID patterns like PROJ-00001 or TASK-00001
        local id = line:match('([A-Z]+-[0-9]+)')
        return id
    end

    local content = vim.fn.systemlist('vimban -f md kanban --mine')
    local buf, win = M.open_float(content, {
        title = 'Kanban Board (? for help)',
        width = 0.92,
        height = 0.85,
        keymaps = {
            ['<CR>'] = function(b, w, close)
                local id = get_ticket_under_cursor()
                if id then
                    close()
                    M.show_ticket_float(id)
                end
            end,
            ['o'] = function(b, w, close)
                local id = get_ticket_under_cursor()
                if id then
                    close()
                    local path = M.get_ticket_filepath(id)
                    if path and path ~= '' then
                        vim.cmd('edit ' .. M.config.notes_dir .. path)
                    end
                end
            end,
            ['m'] = function(b, w, close)
                local id = get_ticket_under_cursor()
                if id then
                    M.move_status(id, function() refresh_kanban(b) end)
                end
            end,
            ['c'] = function(b, w, close)
                local id = get_ticket_under_cursor()
                if id then
                    M.add_comment(id, function() refresh_kanban(b) end)
                end
            end,
            ['e'] = function(b, w, close)
                local id = get_ticket_under_cursor()
                if id then
                    M.edit_ticket(id, function() refresh_kanban(b) end)
                end
            end,
            ['r'] = function(b) refresh_kanban(b) end,
            ['?'] = function()
                local help = {
                    '# Kanban Keybinds',
                    '',
                    '| Key | Action |',
                    '|-----|--------|',
                    '| <CR> | View ticket in float |',
                    '| o | Open ticket file |',
                    '| m | Move ticket status |',
                    '| c | Add comment |',
                    '| e | Edit ticket fields |',
                    '| r | Refresh board |',
                    '| q/Esc | Close |',
                    '| ? | Show this help |',
                }
                M.open_float(help, { title = 'Help' })
            end,
        },
    })
end

-- ============================================================================
-- Ticket List / FZF Functions
-- ============================================================================

-- FZF ticket picker with enhanced actions
function M.fzf_tickets(filter)
    filter = filter or '--mine'
    local fzf_cmd = string.format(
        'vimban --no-color -f plain list %s --no-header | fzf --preview "vimban --no-color -f md show {1}" ' ..
        '--header "enter=open, ctrl-m=move, ctrl-c=comment, ctrl-e=edit" ' ..
        '--expect=ctrl-m,ctrl-c,ctrl-e',
        filter
    )
    local result = vim.fn.system(fzf_cmd)
    local lines = vim.split(vim.fn.trim(result), '\n')

    if #lines < 1 then return end

    local key = lines[1]
    local selection = #lines > 1 and lines[2] or lines[1]
    local id = selection:match('^%S+')

    if not id or id == '' then return end

    if key == 'ctrl-m' then
        M.move_status(id)
    elseif key == 'ctrl-c' then
        M.add_comment(id)
    elseif key == 'ctrl-e' then
        M.edit_ticket(id)
    else
        -- Default: open ticket file
        local path = M.get_ticket_filepath(id)
        if path and path ~= '' then
            vim.cmd('edit ' .. M.config.notes_dir .. path)
        end
    end
end

-- List with filter menu
function M.list_filtered()
    local filters = {
        { label = 'My tickets', filter = '--mine' },
        { label = 'In Progress', filter = '--mine --status in_progress' },
        { label = 'Blocked', filter = '--blocked' },
        { label = 'Due This Week', filter = '--mine --due-soon 7' },
        { label = 'Overdue', filter = '--overdue' },
        { label = 'All tickets', filter = '' },
        { label = 'Custom...', filter = 'custom' },
    }

    local labels = {}
    for _, f in ipairs(filters) do
        table.insert(labels, f.label)
    end

    vim.ui.select(labels, { prompt = 'Filter:' }, function(choice)
        if not choice then return end
        for _, f in ipairs(filters) do
            if f.label == choice then
                if f.filter == 'custom' then
                    vim.ui.input({ prompt = 'vimban list ' }, function(custom)
                        if custom then M.fzf_tickets(custom) end
                    end)
                else
                    M.fzf_tickets(f.filter)
                end
                return
            end
        end
    end)
end

-- ============================================================================
-- Create / Edit Functions
-- ============================================================================

-- Create ticket wizard
function M.create_ticket()
    vim.ui.select(M.config.ticket_types, { prompt = 'Ticket type:' }, function(ttype)
        if not ttype then return end

        vim.ui.input({ prompt = 'Title:' }, function(title)
            if not title or title == '' then return end

            vim.ui.select(M.config.priorities, { prompt = 'Priority:' }, function(priority)
                local cmd = string.format('vimban create %s "%s"', ttype, title)
                if priority then
                    cmd = cmd .. ' --priority ' .. priority
                end

                vim.ui.select({ 'Yes', 'No' }, { prompt = 'Assign to me?' }, function(assign)
                    if assign == 'Yes' then
                        cmd = cmd .. ' --assignee "![[05_people/zach-podbielniak.md]]"'
                    end

                    local result = vim.fn.system(cmd)
                    vim.notify(result, vim.log.levels.INFO)

                    -- Extract ticket ID from result and offer to open
                    local new_id = result:match('Created.*([A-Z]+-[0-9]+)')
                    if new_id then
                        vim.ui.select({ 'Yes', 'No' }, { prompt = 'Open ticket?' }, function(open)
                            if open == 'Yes' then
                                local path = M.get_ticket_filepath(new_id)
                                if path and path ~= '' then
                                    vim.cmd('edit ' .. M.config.notes_dir .. path)
                                end
                            end
                        end)
                    end
                end)
            end)
        end)
    end)
end

-- Edit ticket fields menu
function M.edit_ticket(ticket_id, callback)
    ticket_id = ticket_id or M.get_ticket_id()
    if not ticket_id then
        vim.notify('No ticket ID found', vim.log.levels.WARN)
        return
    end

    local fields = {
        { label = 'Status', action = 'status' },
        { label = 'Priority', action = 'priority' },
        { label = 'Assignee', action = 'assignee' },
        { label = 'Due Date', action = 'due_date' },
        { label = 'Add Tag', action = 'add_tag' },
        { label = 'Remove Tag', action = 'remove_tag' },
        { label = 'Progress', action = 'progress' },
    }

    local labels = {}
    for _, f in ipairs(fields) do
        table.insert(labels, f.label)
    end

    vim.ui.select(labels, { prompt = 'Edit field:' }, function(choice)
        if not choice then return end

        for _, f in ipairs(fields) do
            if f.label == choice then
                if f.action == 'status' then
                    M.move_status(ticket_id, callback)
                elseif f.action == 'priority' then
                    vim.ui.select(M.config.priorities, { prompt = 'Priority:' }, function(p)
                        if p then
                            vim.fn.system('vimban edit ' .. ticket_id .. ' --priority ' .. p)
                            vim.notify('Priority updated', vim.log.levels.INFO)
                            if callback then callback() end
                            vim.cmd('edit!')
                        end
                    end)
                elseif f.action == 'assignee' then
                    vim.ui.input({ prompt = 'Assignee (person ref):' }, function(a)
                        if a and a ~= '' then
                            vim.fn.system('vimban edit ' .. ticket_id .. ' --assignee "' .. a .. '"')
                            vim.notify('Assignee updated', vim.log.levels.INFO)
                            if callback then callback() end
                            vim.cmd('edit!')
                        end
                    end)
                elseif f.action == 'due_date' then
                    vim.ui.input({ prompt = 'Due date (YYYY-MM-DD or +7d):' }, function(d)
                        if d and d ~= '' then
                            vim.fn.system('vimban edit ' .. ticket_id .. ' --due-date ' .. d)
                            vim.notify('Due date updated', vim.log.levels.INFO)
                            if callback then callback() end
                            vim.cmd('edit!')
                        end
                    end)
                elseif f.action == 'add_tag' then
                    vim.ui.input({ prompt = 'Tag to add:' }, function(t)
                        if t and t ~= '' then
                            vim.fn.system('vimban edit ' .. ticket_id .. ' --add-tag ' .. t)
                            vim.notify('Tag added', vim.log.levels.INFO)
                            if callback then callback() end
                            vim.cmd('edit!')
                        end
                    end)
                elseif f.action == 'remove_tag' then
                    vim.ui.input({ prompt = 'Tag to remove:' }, function(t)
                        if t and t ~= '' then
                            vim.fn.system('vimban edit ' .. ticket_id .. ' --remove-tag ' .. t)
                            vim.notify('Tag removed', vim.log.levels.INFO)
                            if callback then callback() end
                            vim.cmd('edit!')
                        end
                    end)
                elseif f.action == 'progress' then
                    vim.ui.input({ prompt = 'Progress (0-100):' }, function(p)
                        if p and p ~= '' then
                            vim.fn.system('vimban edit ' .. ticket_id .. ' --progress ' .. p)
                            vim.notify('Progress updated', vim.log.levels.INFO)
                            if callback then callback() end
                            vim.cmd('edit!')
                        end
                    end)
                end
                return
            end
        end
    end)
end

-- Move ticket status
function M.move_status(ticket_id, callback)
    ticket_id = ticket_id or M.get_ticket_id()
    if not ticket_id then
        vim.notify('No ticket ID found', vim.log.levels.WARN)
        return
    end

    vim.ui.select(M.config.statuses, { prompt = 'New status:' }, function(status)
        if status then
            local cmd = 'vimban move ' .. ticket_id .. ' ' .. status
            if status == 'done' then
                cmd = cmd .. ' --resolve'
            end
            vim.fn.system(cmd)
            vim.notify('Status updated to ' .. status, vim.log.levels.INFO)
            if callback then callback() end
            vim.cmd('edit!')
        end
    end)
end

-- Add comment to ticket
function M.add_comment(ticket_id, callback)
    ticket_id = ticket_id or M.get_ticket_id()
    if not ticket_id then
        vim.notify('No ticket ID found', vim.log.levels.WARN)
        return
    end

    vim.ui.input({ prompt = 'Comment:' }, function(input)
        if input and input ~= '' then
            local cmd = string.format('vimban comment %s %q', ticket_id, input)
            local result = vim.fn.system(cmd)
            vim.notify(result, vim.log.levels.INFO)
            if callback then callback() end
            vim.cmd('edit!')
        end
    end)
end

-- Reply to comment
function M.reply_comment(ticket_id)
    ticket_id = ticket_id or M.get_ticket_id()
    if not ticket_id then
        vim.notify('No ticket ID found', vim.log.levels.WARN)
        return
    end

    vim.ui.input({ prompt = 'Reply to comment #:' }, function(reply_to)
        if reply_to and reply_to ~= '' then
            vim.ui.input({ prompt = 'Reply:' }, function(input)
                if input and input ~= '' then
                    local cmd = string.format('vimban comment %s %q --reply-to %s', ticket_id, input, reply_to)
                    local result = vim.fn.system(cmd)
                    vim.notify(result, vim.log.levels.INFO)
                    vim.cmd('edit!')
                end
            end)
        end
    end)
end

-- ============================================================================
-- Search Functions
-- ============================================================================

-- Search tickets
function M.search_tickets()
    vim.ui.input({ prompt = 'Search query:' }, function(query)
        if not query or query == '' then return end

        local content = vim.fn.systemlist('vimban search "' .. query .. '" --context-lines 2')
        if #content == 0 then
            vim.notify('No results found', vim.log.levels.INFO)
            return
        end

        M.open_float(content, {
            title = 'Search: ' .. query,
            width = 0.85,
            height = 0.8,
            keymaps = {
                ['<CR>'] = function(buf, win, close)
                    local line = vim.api.nvim_get_current_line()
                    local id = line:match('([A-Z]+-[0-9]+)')
                    if id then
                        close()
                        local path = M.get_ticket_filepath(id)
                        if path and path ~= '' then
                            vim.cmd('edit ' .. M.config.notes_dir .. path)
                        end
                    end
                end,
            },
        })
    end)
end

-- ============================================================================
-- People Functions
-- ============================================================================

-- People dashboard picker
function M.people_dashboard()
    local result = vim.fn.system('vimban --no-color -f plain people list --no-header | fzf --preview "vimban --no-color -f md people show {1}"')
    local person = vim.fn.trim(result)
    if person and person ~= '' then
        local content = vim.fn.systemlist('vimban -f md dashboard person --person "' .. person .. '"')
        M.open_float(content, {
            title = 'Person: ' .. person,
            width = 0.85,
            height = 0.85,
        })
    end
end

-- ============================================================================
-- Link / Navigation Functions
-- ============================================================================

-- Insert transclusion link at cursor
function M.insert_link()
    local fzf_cmd = 'vimban --no-color -f plain list --no-header | fzf --preview "vimban --no-color -f md show {1}"'
    local result = vim.fn.system(fzf_cmd)
    local id = vim.fn.trim(result):match('^%S+')

    if id and id ~= '' then
        local path = M.get_ticket_filepath(id)
        if path and path ~= '' then
            local link = '![[' .. path .. ']]'
            vim.api.nvim_put({ link }, 'c', true, true)
        end
    end
end

-- Show ticket under cursor in float
function M.show_ticket_float(ticket_id)
    ticket_id = ticket_id or M.get_ticket_id()
    if not ticket_id then
        vim.notify('No ticket ID found', vim.log.levels.WARN)
        return
    end

    local content = vim.fn.systemlist('vimban -f md show ' .. ticket_id)
    M.open_float(content, {
        title = ticket_id .. ' (? for help)',
        width = 0.8,
        height = 0.8,
        keymaps = {
            ['<CR>'] = function(buf, win, close)
                close()
                local path = M.get_ticket_filepath(ticket_id)
                if path and path ~= '' then
                    vim.cmd('edit ' .. M.config.notes_dir .. path)
                end
            end,
            ['m'] = function() M.move_status(ticket_id) end,
            ['c'] = function() M.add_comment(ticket_id) end,
            ['e'] = function() M.edit_ticket(ticket_id) end,
            ['?'] = function()
                local help = {
                    '# Ticket Float Keybinds',
                    '',
                    '| Key | Action |',
                    '|-----|--------|',
                    '| <CR> | Open ticket file |',
                    '| m | Move ticket status |',
                    '| c | Add comment |',
                    '| e | Edit ticket fields |',
                    '| q/Esc | Close |',
                    '| ? | Show this help |',
                }
                M.open_float(help, { title = 'Help' })
            end,
        },
    })
end

-- Go to ticket file from transclusion under cursor
function M.goto_ticket()
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.')

    -- Check for transclusion: ![[path]]
    for s, path, e in line:gmatch('()!%[%[([^%]]+)%]%]()') do
        if col >= s and col <= e then
            local full = M.config.notes_dir .. path
            if vim.fn.filereadable(full) == 1 then
                vim.cmd('edit ' .. full)
            end
            return
        end
    end

    -- Check for markdown link: [title](path)
    for s, _, path, e in line:gmatch('()%[([^%]]+)%]%(([^%)]+)%)()') do
        if col >= s and col <= e then
            if not path:match('^https?://') then
                local full = M.config.notes_dir .. path
                if vim.fn.filereadable(full) == 1 then
                    vim.cmd('edit ' .. full)
                end
            end
            return
        end
    end

    -- Try to get ticket ID from line and open
    local id = line:match('([A-Z]+-[0-9]+)')
    if id then
        local path = M.get_ticket_filepath(id)
        if path and path ~= '' then
            vim.cmd('edit ' .. M.config.notes_dir .. path)
        end
    end
end

-- ============================================================================
-- Regenerate Section
-- ============================================================================

-- Regenerate VIMBAN section under cursor
function M.regenerate_section()
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
end

-- ============================================================================
-- Visual Mode Functions
-- ============================================================================

-- Create ticket from visual selection
function M.create_from_selection()
    local lines = vim.fn.getline("'<", "'>")
    local title = table.concat(lines, ' ')
    vim.ui.select(M.config.ticket_types, { prompt = 'Type:' }, function(t)
        if t then
            local cmd = string.format('vimban create %s "%s"', t, title)
            local result = vim.fn.system(cmd)
            vim.notify(result, vim.log.levels.INFO)
        end
    end)
end

-- ============================================================================
-- Help System
-- ============================================================================

-- Show vimban keybinds help
function M.show_help()
    local help = {
        '# Vimban Keybinds',
        '',
        '## Global Mappings (<leader>v)',
        '',
        '| Key | Description |',
        '|-----|-------------|',
        '| `<leader>vd` | Daily dashboard |',
        '| `<leader>vD` | Dashboard picker (daily/weekly/sprint/project/person) |',
        '| `<leader>vk` | Kanban board (interactive) |',
        '| `<leader>vl` | FZF ticket picker (my tickets) |',
        '| `<leader>vL` | List with filter menu |',
        '| `<leader>vc` | Create ticket wizard |',
        '| `<leader>vC` | Add comment to current ticket |',
        '| `<leader>vr` | Reply to comment |',
        '| `<leader>vm` | Move ticket status |',
        '| `<leader>ve` | Edit ticket fields |',
        '| `<leader>vs` | Search tickets |',
        '| `<leader>vp` | People picker/dashboard |',
        '| `<leader>vi` | Insert transclusion link |',
        '| `<leader>vf` | View ticket under cursor in float |',
        '| `<leader>vg` | Go to ticket file from transclusion |',
        '| `<leader>vR` | Regenerate VIMBAN section |',
        '| `<leader>v?` | Show this help |',
        '',
        '## Visual Mode',
        '',
        '| Key | Description |',
        '|-----|-------------|',
        '| `<leader>vc` | Create ticket from selection |',
        '',
        '## Float Window Actions',
        '',
        '| Key | Action |',
        '|-----|--------|',
        '| `q` / `<Esc>` | Close window |',
        '| `<CR>` | Open/View ticket |',
        '| `m` | Move status |',
        '| `c` | Add comment |',
        '| `e` | Edit fields |',
        '| `r` | Refresh (kanban) |',
        '| `o` | Open file (kanban) |',
        '| `?` | Show context help |',
        '',
        '## Buffer-Local Mappings (in ticket files)',
        '',
        '| Key | Description |',
        '|-----|-------------|',
        '| `<localleader>m` | Move this ticket |',
        '| `<localleader>c` | Add comment |',
        '| `<localleader>e` | Edit fields |',
    }
    M.open_float(help, { title = 'Vimban Help', width = 0.7, height = 0.85 })
end

-- ============================================================================
-- Autocmds and Buffer-Local Setup
-- ============================================================================

-- Setup buffer-local mappings for ticket files
function M.setup_buffer_local()
    -- Check if current buffer is a ticket file (has id: in frontmatter)
    local lines = vim.api.nvim_buf_get_lines(0, 0, 30, false)
    local is_ticket = false
    for _, line in ipairs(lines) do
        if line:match('^id:%s*"?[A-Z]+-[0-9]+') then
            is_ticket = true
            break
        end
    end

    if is_ticket then
        local opts = { buffer = 0, silent = true }
        vim.keymap.set('n', '<localleader>m', M.move_status, opts)
        vim.keymap.set('n', '<localleader>c', function() M.add_comment() end, opts)
        vim.keymap.set('n', '<localleader>e', function() M.edit_ticket() end, opts)
    end
end

-- Setup autocmds
function M.setup_autocmds()
    local group = vim.api.nvim_create_augroup('VimbanTickets', { clear = true })

    vim.api.nvim_create_autocmd({ 'BufRead', 'BufNewFile' }, {
        group = group,
        pattern = {
            '*/01_projects/*.md',
            '*/02_areas/*.md',
            '*/.vimban/*.md',
        },
        callback = function()
            -- Defer to allow buffer to load
            vim.defer_fn(M.setup_buffer_local, 100)
        end,
    })
end

-- Initialize module
function M.setup()
    M.setup_autocmds()
end

return M
