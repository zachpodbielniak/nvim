local options = {
  ensure_installed = { "lua", "vim", "vimdoc", "xml", "html" },

  highlight = {
    enable = true,
    use_languagetree = true,
  },

  indent = { enable = true },
}

local parser_config = require "nvim-treesitter.parsers".get_parser_configs()
parser_config.just = {
  install_info = {
    url = "https://github.com/IndianBoy42/tree-sitter-just", -- local path or git repo
    files = { "src/parser.c", "src/scanner.c" },
    branch = "main",
    -- use_makefile = true -- this may be necessary on MacOS (try if you see compiler errors)
  },
  maintainers = { "@IndianBoy42" },
}

return options
