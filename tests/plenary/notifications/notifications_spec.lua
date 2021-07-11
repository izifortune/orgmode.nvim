local parser = require('orgmode.parser')
local Files = require('orgmode.parser.files')
local Date = require('orgmode.objects.date')
local Notifications = require('orgmode.notifications')

describe('Notifications', function()
  it('should find headlines for notification', function()
    local filename = vim.fn.tempname()
    local lines = {
      '* TODO I am the deadline task :OFFICE:',
      '  DEADLINE: <2021-07-12 Mon 12:30>',
      '* TODO I am the scheduled task',
      '  SCHEDULED: <2021-07-12 Mon 12:30>',
      '* TODO I am the deadline task for evening',
      '  DEADLINE: <2021-07-12 Mon 19:30>',
      '* TODO I am the scheduled task for evening',
      '  SCHEDULED: <2021-07-12 Mon 19:30>',
    }
    local orgfile = parser.parse(lines, 'work', filename)
    Files.files[filename] = orgfile
    local notifications = Notifications:new()
    assert.are.same({}, notifications:get_tasks(Date.from_string('2021-07-11 Sun 12:30')))
    assert.are.same({}, notifications:get_tasks(Date.from_string('2021-07-12 Mon 10:30')))
    local first_heading = orgfile:get_item(1)
    local second_heading = orgfile:get_item(3)
    assert.are.same({
      {
        file = filename,
        todo = 'TODO',
        line = lines[1],
        category = 'work',
        priority = '',
        title = 'I am the deadline task',
        tags = {'OFFICE'},
        date = first_heading.dates[1]:to_string(),
        timestamp = first_heading.dates[1].timestamp,
        type = 'DEADLINE',
      },
      {
        file = filename,
        todo = 'TODO',
        line = lines[3],
        category = 'work',
        priority = '',
        title = 'I am the scheduled task',
        tags = {},
        date = second_heading.dates[1]:to_string(),
        timestamp = second_heading.dates[1].timestamp,
        type = 'SCHEDULED',
      },
    }, notifications:get_tasks(Date.from_string('2021-07-12 Mon 12:20')))
  end)

  it('should find repeatable and warning deadlines for notification', function()
    local filename = vim.fn.tempname()
    local lines = {
      '* TODO I am the deadline task :OFFICE:',
      '  DEADLINE: <2021-07-07 Wed 12:30 +1w>',
      '* TODO I am the scheduled task',
      '  SCHEDULED: <2021-07-14 Wed 12:30>',
      '* TODO I am the deadline task for evening',
      '  DEADLINE: <2021-07-14 Wed 19:30 -7h>',
      '* TODO I am the scheduled task for evening',
      '  SCHEDULED: <2021-07-14 Wed 19:30>',
    }
    local orgfile = parser.parse(lines, 'work', filename)
    Files.files[filename] = orgfile
    local notifications = Notifications:new()
    assert.are.same({}, notifications:get_tasks(Date.from_string('2021-07-13 Sun 12:30')))
    assert.are.same({}, notifications:get_tasks(Date.from_string('2021-07-14 Mon 10:30')))
    local first_heading = orgfile:get_item(1)
    local second_heading = orgfile:get_item(3)
    local third_heading = orgfile:get_item(5)

    local time = Date.from_string('2021-07-14 Mon 12:20')
    local tasks = notifications:get_tasks(time)

    assert.are.same({
      {
        file = filename,
        todo = 'TODO',
        line = lines[1],
        category = 'work',
        priority = '',
        title = 'I am the deadline task',
        tags = {'OFFICE'},
        date = first_heading.dates[1]:with_adjustments_for_date(time):to_string(),
        timestamp = first_heading.dates[1]:with_adjustments_for_date(time).timestamp,
        type = 'DEADLINE',
      },
      {
        file = filename,
        todo = 'TODO',
        line = lines[3],
        category = 'work',
        priority = '',
        title = 'I am the scheduled task',
        tags = {},
        date = second_heading.dates[1]:with_adjustments_for_date(time):to_string(),
        timestamp = second_heading.dates[1]:with_adjustments_for_date(time).timestamp,
        type = 'SCHEDULED',
      },
      {
        file = filename,
        todo = 'TODO',
        line = lines[5],
        category = 'work',
        priority = '',
        title = 'I am the deadline task for evening',
        tags = {},
        date = third_heading.dates[1]:with_adjustments_for_date(time):to_string(),
        timestamp = third_heading.dates[1]:with_adjustments_for_date(time).timestamp,
        type = 'DEADLINE',
      },
    }, tasks)
  end)
end)

