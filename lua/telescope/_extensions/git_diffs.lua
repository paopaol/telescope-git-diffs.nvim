local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require "telescope.previewers"
local conf = require('telescope.config').values
local make_entry = require "telescope.make_entry"
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local utils = require "telescope.utils"


M = {}

local setup_opts = {
  git_command = { "git", "log", "--oneline", "--decorate", "--all", "." },
  use_gitsigns = false,
}

M.setup = function(opts)
    setup_opts = vim.tbl_deep_extend("force", setup_opts, opts)
end

local function diffthis(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local selections = picker:get_multi_selection()

  actions.close(prompt_bufnr)

  if #selections > 1 then
    utils.notify("diff_commits", { level = "WARN", msg = "must select only 1 commit" })
    return
  end


  local commit = #selections == 0 and string.sub(action_state.get_selected_entry().ordinal, 1, 7) or
                                   string.sub(selections[1].value, 1, 8)

  vim.cmd(string.format("Gitsigns diffthis %s", commit))

  vim.cmd([[stopinsert]])
end

local function diffview(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local selections = picker:get_multi_selection()

  actions.close(prompt_bufnr)


  if #selections > 2 then
    utils.notify("diff_commits", { level = "WARN", msg = "must select 1 or 2 commits" })
    return
  end


  -- Sort by date
  table.sort(selections, function(a, b)
    return tonumber(vim.fn.systemlist("git show -s --format=%ct " .. a.value)[1]) <
           tonumber(vim.fn.systemlist("git show -s --format=%ct " .. b.value)[1])
  end)

  local old = #selections == 0 and string.sub(action_state.get_selected_entry().ordinal, 1, 7) or
                                   string.sub(selections[1].value, 1, 8)

  if #selections == 2 then
    local new = string.sub(selections[2].value, 1, 8)
    vim.cmd(string.format("DiffviewOpen %s..%s", old, new))
  else
    vim.cmd(string.format("DiffviewOpen %s^!", old))
  end

  vim.cmd([[stopinsert]])
end

M.diff_commits = function (opts)
  opts = opts or {}
  opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_git_commits(opts))


  pickers.new(opts, {
    prompt_title = opts.prompt_title or "git diff_commits",
    finder = finders.new_oneshot_job(setup_opts.git_command, opts),
    previewer = {
      previewers.git_commit_diff_to_parent.new(opts),
      previewers.git_commit_diff_to_head.new(opts),
      previewers.git_commit_diff_as_was.new(opts),
      previewers.git_commit_message.new(opts),
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = opts.attach_mappings or function(_, map)
      if opts.use_gitsigns == false then
        actions.select_default:replace(diffview)
      else
        actions.select_default:replace(diffthis)
      end
      return true
    end
  }):find()
end

return require('telescope').register_extension {
  setup = M.setup,
  exports = {
    diff_commits = M.diff_commits,
  }
}

