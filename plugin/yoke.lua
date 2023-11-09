-- vim.api.nvim_create_user_command("MoveCursor", function(args)
--   -- require("yoke").MoveCursor(args['args'][1], args['args'][2])
--   -- print("here")
--   print(dump(args))
--   print(dump(args))
-- end, { desc = "Yoke move cursor", nargs = '*' })


local yoke = require('yoke')
vim.api.nvim_create_user_command('MoveCursor', function(opts)
  -- print(dump(opts))
  opts.fargs[1] = opts.fargs[1] or ''
  opts.fargs[2] = opts.fargs[2] or ''

  yoke.MoveCursor(opts.fargs[1], opts.fargs[2])
end, { nargs='*' })
  -- require("yoke").MoveCursor, {})
-- vim.api.nvim_create_user_command("VMoveCursor", require("yoke").VMoveCursor, {})
--

vim.api.nvim_create_user_command('VMoveCursor', function(opts)
  opts.fargs[1] = opts.fargs[1] or ''
  opts.fargs[2] = opts.fargs[2] or ''
  yoke.VMoveCursor(opts.fargs[1], opts.fargs[2])
end, { nargs='*' })
