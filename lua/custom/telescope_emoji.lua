-- telescope_emoji.lua - Emoji picker using telescope and the emoji script
-- Provides a telescope picker for searching and inserting emojis at cursor position

local M = {}

-- Configuration
M.config = {
    -- Path to emoji command (should be in PATH)
    emoji_cmd = 'emoji',
}

-- Cache for emoji data (loaded once per session)
local emoji_cache = nil

-- Load emojis from the emoji command
-- Returns a table of { shortcode, emoji, name, category }
local function load_emojis()
    if emoji_cache then
        return emoji_cache
    end

    local output = vim.fn.systemlist(M.config.emoji_cmd .. ' --list')
    if vim.v.shell_error ~= 0 then
        vim.notify('Failed to load emojis from emoji command', vim.log.levels.ERROR)
        return {}
    end

    emoji_cache = {}
    for _, line in ipairs(output) do
        -- Parse TSV: shortcode\temoji\tname\tcategory
        local parts = vim.split(line, '\t')
        if #parts >= 4 then
            table.insert(emoji_cache, {
                shortcode = parts[1],
                emoji = parts[2],
                name = parts[3],
                category = parts[4],
            })
        end
    end

    return emoji_cache
end

-- Telescope emoji picker
-- Opens a telescope picker for emojis, inserts selected emoji at cursor
function M.pick_emoji()
    local ok, telescope = pcall(require, 'telescope')
    if not ok then
        vim.notify('Telescope is required for emoji picker', vim.log.levels.ERROR)
        return
    end

    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local conf = require('telescope.config').values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    local entry_display = require('telescope.pickers.entry_display')

    local emojis = load_emojis()
    if #emojis == 0 then
        vim.notify('No emojis loaded', vim.log.levels.WARN)
        return
    end

    -- Create display format: emoji  shortcode - name (category)
    local displayer = entry_display.create {
        separator = ' ',
        items = {
            { width = 2 },   -- emoji
            { width = 25 },  -- shortcode
            { width = 35 },  -- name
            { remaining = true }, -- category
        },
    }

    local make_display = function(entry)
        return displayer {
            { entry.emoji, 'TelescopeResultsIdentifier' },
            { entry.shortcode, 'TelescopeResultsVariable' },
            { entry.name, 'TelescopeResultsComment' },
            { '(' .. entry.category .. ')', 'TelescopeResultsNumber' },
        }
    end

    pickers.new({}, {
        prompt_title = 'Emoji Picker',
        finder = finders.new_table {
            results = emojis,
            entry_maker = function(entry)
                -- Search text includes all fields for fuzzy matching
                local search_text = entry.shortcode .. ' ' .. entry.name .. ' ' .. entry.category
                return {
                    value = entry,
                    display = make_display,
                    ordinal = search_text,
                    shortcode = entry.shortcode,
                    emoji = entry.emoji,
                    name = entry.name,
                    category = entry.category,
                }
            end,
        },
        sorter = conf.generic_sorter({}),
        attach_mappings = function(prompt_bufnr, map)
            -- Insert emoji at cursor on selection
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    -- Insert emoji at cursor position
                    local emoji = selection.emoji
                    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                    local line = vim.api.nvim_get_current_line()
                    local new_line = line:sub(1, col) .. emoji .. line:sub(col + 1)
                    vim.api.nvim_set_current_line(new_line)
                    -- Move cursor after the inserted emoji
                    vim.api.nvim_win_set_cursor(0, { row, col + #emoji })
                end
            end)

            -- Copy emoji to clipboard with ctrl-y
            map('i', '<C-y>', function()
                local selection = action_state.get_selected_entry()
                if selection then
                    vim.fn.setreg('+', selection.emoji)
                    vim.notify('Copied: ' .. selection.emoji, vim.log.levels.INFO)
                end
            end)

            -- Insert shortcode instead of emoji with ctrl-s
            map('i', '<C-s>', function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                if selection then
                    local shortcode = ':' .. selection.shortcode .. ':'
                    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                    local line = vim.api.nvim_get_current_line()
                    local new_line = line:sub(1, col) .. shortcode .. line:sub(col + 1)
                    vim.api.nvim_set_current_line(new_line)
                    vim.api.nvim_win_set_cursor(0, { row, col + #shortcode })
                end
            end)

            return true
        end,
    }):find()
end

-- Clear emoji cache (useful if emoji data file is updated)
function M.clear_cache()
    emoji_cache = nil
    vim.notify('Emoji cache cleared', vim.log.levels.INFO)
end

-- Setup commands
function M.setup()
    vim.api.nvim_create_user_command('Emoji', function()
        M.pick_emoji()
    end, { desc = 'Open emoji telescope picker' })

    vim.api.nvim_create_user_command('EmojiClearCache', function()
        M.clear_cache()
    end, { desc = 'Clear emoji cache' })
end

return M
