local Notification = {}

function Notification:new(opts)
  local data = {
    type = opts.type or 'info',
    content = opts.content or nil,
    buf = nil,
    win = nil,
  }
  setmetatable(data, self)
  self.__index = self
  data:show()
  return data
end

function Notification:show()
  if not self.content or self.content == '' then return end
  local opts = {
    relative = 'editor',
    width = 50,
    height = 2,
    style = 'minimal',
    border = 'single',
    anchor = 'NE',
    row = 0,
    col = vim.o.columns - 1,
    focusable = false,
  }
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, self.content)
  vim.api.nvim_buf_set_option(self.buf, 'filetype', 'org')
  self.win = vim.api.nvim_open_win(self.buf, false, opts)
  vim.api.nvim_win_set_option(self.win, 'winhl', 'FloatBorder:Error,Normal:Normal')
end

return Notification
