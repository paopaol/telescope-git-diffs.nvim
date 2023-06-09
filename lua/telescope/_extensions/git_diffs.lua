local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require "telescope.previewers"
local conf = require('telescope.config').values
local make_entry = require "telescope.make_entry"
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local utils = require "telescope.utils"


local function diffview(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local selections = picker:get_multi_selection()

  actions.close(prompt_bufnr)


  if #selections < 1 or #selections > 2 then
    utils.notify("diff_commits", { level = "WARN", msg = "must select 1 or 2 commits" })
    return
  end


  -- Sort by date
  table.sort(selections, function(a, b)
    return tonumber(vim.fn.systemlist("git show -s --format=%ct " .. a.value)[1]) <
           tonumber(vim.fn.systemlist("git show -s --format=%ct " .. b.value)[1])
  end)

  local old = string.sub(selections[1].value, 1, 8)

  if #selections == 1 then
    vim.cmd(string.format("DiffviewOpen %s^!", old))
  else
    local new = string.sub(selections[2].value, 1, 8)
    vim.cmd(string.format("DiffviewOpen %s..%s", old, new))
  end

  vim.cmd([[stopinsert]])
end

local function diff_commits(opts)
  opts = opts or {}
  opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_git_commits(opts))


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
      return true
    end
  }):find()
end

return require('telescope').register_extension {
  exports = {
    diff_commits = diff_commits,
  }
}
