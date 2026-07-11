local function warn(msg)
  vim.api.nvim_echo({{msg, 'WarningMsg'}}, false, {})
end

local ok_lsp, lspconfig = pcall(require, 'lspconfig')
if not ok_lsp then
  warn('[nvim] lspconfig not found; skipping texlab setup')
else
  local function has(bin) return vim.fn.executable(bin) == 1 end
  if has('texlab') == false then warn('[nvim] texlab not found in PATH') end
  if has('tectonic') == false then warn('[nvim] tectonic not found in PATH') end
  if has('zathura') == false then warn('[nvim] zathura not found in PATH') end


  lspconfig.texlab.setup({
    settings = {
      texlab = {
        auxDirectory = "build",
        build = {
          executable = "tectonic",
          args = { "-X", "compile", "--synctex", "--outdir", "build", "%f" },
          onSave = true,
          forwardSearchAfter = true,
        },
        forwardSearch = {
          executable = "zathura",
          args = { "--synctex-forward", "%l:1:%f", "%p" }
        },
        chktex = { onOpenAndSave = false },
      }
    }
  }) 
end




vim.o.updatetime = 2000
vim.o.autowriteall = true   -- write on :make, :quit as a safety net

local autosave_group = vim.api.nvim_create_augroup("TeXAutoSave", { clear = true })

local function ensure_timer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then return nil end
  if not vim.b[bufnr]._autosave_timer then
    vim.b[bufnr]._autosave_timer = vim.loop.new_timer()
  end
  return vim.b[bufnr]._autosave_timer
end


local function debounced_write(bufnr)
  local t = ensure_timer(bufnr)
  if not t then return end
  t:stop()
  t:start(2000, 0, function()
    vim.schedule(function()
      if not vim.api.nvim_buf_is_loaded(bufnr) then return end
      if not vim.bo[bufnr].modifiable then return end
      if vim.bo[bufnr].modified then
        vim.api.nvim_buf_call(bufnr, function()
          pcall(vim.cmd.write)
        end)
      end
    end)
  end)
end

vim.api.nvim_create_autocmd(
  { 'TextChanged', 'TextChangedI', 'CursorHold', 'CursorHoldI', 'InsertLeave', 'FocusLost' },
  {
    group = autosave_group,
    pattern = '*.tex',
    callback = function(args) debounced_write(args.buf) end,
  }
)



-- global defaults
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.shiftround = true


vim.opt.termguicolors = true
vim.opt.background = 'dark'
pcall(vim.cmd.colorscheme, 'industry')
