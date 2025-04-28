local api = vim.api
local a = setmetatable({}, {
  ---@param name string
  ---@param tbl table<string, table> { ev1 = args1, ev2 = args2, ... }
  __newindex = function(_, name, tbl)
    local id = api.nvim_create_augroup(name, {})
    for event, opts in pairs(tbl) do
      local ev = vim.split(event, ',')
      local ty = type(opts)
      if ty == 'string' then
        opts = { command = opts }
      elseif ty == 'function' then
        opts = { callback = opts }
      elseif opts[1] then -- is list
        for _, o in ipairs(opts) do
          o.group = id
          api.nvim_create_autocmd(ev, o)
        end
        return
      end
      opts.group = id
      api.nvim_create_autocmd(ev, opts)
    end
  end,
})

a.termmode = {
  TermOpen = function(ev)
    -- why :term won't trigger BufEnter...
    if ev.buf == api.nvim_get_current_buf() then
      vim.defer_fn(function() vim.cmd [[startinsert]] end, 10)
    end
    vim.keymap.set({ 'n', 't' }, '<c-\\><c-n>', '<cmd>let b:term_insert=0<cr><c-\\><c-n>')
  end,
  ModeChanged = { pattern = '*:t', command = [[let b:term_insert = 1]] },
  BufEnter = {
    pattern = { 'term://*' },
    callback = function(ev)
      local b = vim.b[ev.buf]
      if b.term_insert == nil or b.term_insert == 1 then
        vim.defer_fn(function() vim.cmd [[startinsert]] end, 10)
        return
      end
      -- when switch buf, or pty jobstop...
      vim.defer_fn(function()
        vim.cmd [[stopinsert]]
        vim.defer_fn(function()
          if b.term_pos then api.nvim_win_set_cursor(0, b.term_pos) end
        end, 10)
      end, 10)
    end,
  },
  BufLeave = {
    pattern = { 'term://*' },
    callback = function(ev)
      local save = api.nvim_win_get_cursor(0)
      vim.b[ev.buf].term_pos = save
    end,
  },
}
