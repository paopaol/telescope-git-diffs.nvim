local entry_display = require "telescope.pickers.entry_display"
local utils = require "telescope.utils"
local make_entry = require "telescope.make_entry"
local strings = require "plenary.strings"
local Path = require "plenary.path"

local M = {}

function M.gen_from_git_commits(opts)
  opts = opts or {}

  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 12 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    return displayer {
      { vim.F.if_nil(entry.value, ""), "TelescopeResultsIdentifier" },
      entry.msg,
    }
  end

  return function(entry)
    if entry == "" then
      return nil
    end

    entry = string.gsub(entry, "^([^a-z0-9A-Z]+) ([0-9a-zA-Z]+ )", "%2%1 ")
    entry = string.gsub(entry, "^[^0-9a-zA-Z]+$", "%1")
    local sha, msg = string.match(entry, "([0-9a-zA-Z]+) (.+)")

    if not msg then
      sha = nil
      msg = entry
    end


    return make_entry.set_default_entry_mt({
      value = sha,
      ordinal = entry,
      msg = msg,
      display = make_display,
      current_file = opts.current_file,
    }, opts)
  end
end

return M
