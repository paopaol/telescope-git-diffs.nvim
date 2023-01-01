local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require "telescope.previewers"
local entry_display = require('telescope.pickers.entry_display')
local conf = require('telescope.config').values
local make_entry = require('telescope.make_entry')

local utils = require('telescope.utils')

local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local bookmark_actions = require('telescope._extensions.git_diffs.actions')


local function diffview(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local cwd = action_state.get_current_picker(prompt_bufnr).cwd
  local selections = picker:get_multi_selection()


  actions.close(prompt_bufnr)
  local new = string.sub(selections[1].value, 1, 8)
  local old = string.sub(selections[2].value, 1, 8)
  vim.cmd(string.format("DiffviewOpen -uno %s %s", old, new))
end

local function diff_commits(opts)
  opts = opts or {}


  local git_command = { "git", "log", "--oneline", "--decorate", "--all", "." }
  pickers.new(opts, {
    prompt_title = opts.prompt_title or "git diff_commits",
    finder = finders.new_oneshot_job(git_command, opts),
    previewer = {
      previewers.git_commit_diff_to_parent.new(opts),
      previewers.git_commit_diff_to_head.new(opts),
      previewers.git_commit_diff_as_was.new(opts),
      previewers.git_commit_message.new(opts),
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = opts.attach_mappings or function(_, map)
      actions.select_default:replace(diffview)
      map("i", "<M-c>", bookmark_actions.delete_selected_or_at_cursor:enhance { post = refresh_picker })
      return true
    end
  }):find()
end

return require('telescope').register_extension {
  exports = {
    diff_commits = diff_commits,
  }
}
