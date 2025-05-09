local api, fn = vim.api, vim.fn
---START INJECT tmode.lua

local M = {}

local ns = api.nvim_create_augroup('u.tmode', { clear = true })

M.enable = function()
  api.nvim_create_autocmd('TermEnter', { -- https://github.com/neovim/neovim/issues/26881
    group = ns,
    command = [[let b:term_insert = 1]],
  })
  api.nvim_create_autocmd('TermOpen', {
    group = ns,
    callback = function(ev)
      vim.defer_fn(function()
        local ft = vim.bo[ev.buf].ft
        if ft == 'fzf' or ft == 'PlenaryTestPopup' then return end
        vim.b[ev.buf].term_insert = 1
        if api.nvim_get_current_buf() ~= ev.buf or ft ~= '' then return end
        vim.cmd [[startinsert]]
      end, 10)
      vim.keymap.set(
        { 'n', 't' },
        '<c-\\><c-n>',
        '<cmd>let b:term_insert=0<cr><c-\\><c-n>',
        { buffer = ev.buf }
      )
      vim.keymap.set({ 'n' }, 'q', function()
        local chan = vim.bo.channel
        local is_running = fn.jobwait({ chan }, 0)[1] == -1
        return is_running and fn.jobstop(chan) or vim.cmd [[bwipe!]]
      end, { buffer = ev.buf })
    end,
  })
  api.nvim_create_autocmd('BufWinEnter', {
    group = ns,
    pattern = 'term://*',
    callback = function(ev)
      local b = vim.b[ev.buf]
      vim.defer_fn(function()
        if not api.nvim_buf_is_valid(ev.buf) or api.nvim_get_current_buf() ~= ev.buf then return end
        if assert(b.term_insert) == 1 then
          vim.cmd [[startinsert]]
          return
        end
        vim.cmd [[stopinsert]]
        vim.defer_fn(function()
          if not api.nvim_buf_is_valid(ev.buf) or not b.term_pos then return end
          for _, w in ipairs(fn.win_findbuf(ev.buf)) do
            api.nvim_win_set_cursor(w, b.term_pos)
          end
        end, 10)
      end, 10)
    end,
  })
  api.nvim_create_autocmd('BufLeave', {
    group = ns,
    pattern = 'term://*',
    command = [[let b:term_pos = nvim_win_get_cursor(0)]],
  })
end

M.disable = function() api.nvim_create_augroup('u.tmode', { clear = true }) end

return M
