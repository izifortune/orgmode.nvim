local Date = require('orgmode.objects.date')
local Files = require('orgmode.parser.files')
local config = require('orgmode.config')

---@class Notifications
---@field timer table
local Notifications = {}

function Notifications:new()
  local data = {
    timer = nil,
  }
  setmetatable(data, self)
  self.__index = self
  return data
end

function Notifications:start_timer()
  self:stop_timer()
  self.timer = vim.loop.new_timer()
  self:notify(Date.now():start_of('minute'))
  self.timer:start((60 - os.date('%S')) * 1000, 60000, function()
    self:notify(Date.now())
  end)
end

function Notifications:stop_timer()
  if self.timer then
    self.timer:close()
    self.timer = nil
  end
end

---@param time Date
function Notifications:notify(time)
  local tasks = self:get_tasks(time)
  for _, task in ipairs(tasks) do
    vim.loop.spawn('notify-send', { args = {
      '--app-name=orgmode.nvim',
      '--icon=/home/kristijan/github/orgmode.nvim/assets/orgmode_nvim.png',
      string.format('%s\n%s\n%s: %s', task.category, task.line, task.type, task.date),
    }})
  end
end

function Notifications:cron()
  self:notify(Date.now():start_of('minute'))
  vim.cmd[[qall!]]
end

---@param time Date
function Notifications:get_tasks(time)
  local tasks = {}
  for _, orgfile in ipairs(Files.all()) do
    for _, headline in ipairs(orgfile:get_opened_unfinished_headlines()) do
      for _, date in ipairs(headline:get_deadline_and_scheduled_dates()) do
        -- TODO: Check warning time
        -- TODO: Check repeater time
        -- TODO: Check 10 min (warning_time setting) before
        local adjusted_date = date:with_adjustments_for_date(time)
        local d = adjusted_date:diff(time, 'minute')
        if d == config.notifications.warning_time then
          table.insert(tasks, {
            file = headline.file,
            todo = headline.todo_keyword.value,
            line = headline.line,
            category = headline.category,
            priority = headline.priority,
            title = headline.title,
            tags = headline.tags,
            date = adjusted_date:to_string(),
            timestamp = adjusted_date.timestamp,
            type = adjusted_date.type,
          })
        end
      end
    end
  end

  return tasks
end


return Notifications
