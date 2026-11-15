local map = vim.keymap.set

map("i", "jk", "<Esc>")

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Move selected lines in visual mode
map("v", "<A-j>", ":m '>+1<CR>gv=gv")
map("v", "<A-k>", ":m '<-2<CR>gv=gv")

-- Saving / quitting
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR><Esc>", { desc = "Save" })
map("n", "<leader>Q", "<cmd>quitall<CR>", { desc = "Quit all" })
map("n", "<leader>x", "<cmd>xit<CR>", { desc = "Save and quit" })

-- Move by visual line when a line is wrapped (but keep counts like 5j working)
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- Keep the cursor centered when scrolling and searching
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Move current line up/down in normal and insert mode
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("i", "<A-j>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move line down" })
map("i", "<A-k>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move line up" })

-- Keep selection after indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Join lines without moving the cursor
map("n", "J", "mzJ`z")

-- Paste over a selection without losing the yanked text
map("x", "<leader>p", [["_dP]], { desc = "Paste without overwriting register" })

-- Delete without touching the default register
map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole" })

-- Select the whole file
map("n", "<leader>a", "ggVG", { desc = "Select all" })

-- Add undo breakpoints at punctuation so undo is less coarse
map("i", ",", ",<C-g>u")
map("i", ".", ".<C-g>u")
map("i", ";", ";<C-g>u")

-- Add blank line above/below without leaving normal mode
map("n", "]<Space>", "o<Esc>k", { desc = "Blank line below" })
map("n", "[<Space>", "O<Esc>j", { desc = "Blank line above" })

-- Replace the word under the cursor across the whole file
map("n", "<leader>sr", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- Replace the current visual selection across the whole file
map("v", "<leader>sr", [["hy:%s/<C-r>h/<C-r>h/gI<Left><Left><Left>]], { desc = "Replace selection" })

-- Buffers
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bb", "<cmd>b#<CR>", { desc = "Switch to last buffer" })

-- Windows & splits
map("n", "<leader>sv", "<cmd>vsplit<CR>", { desc = "Vertical split" })
map("n", "<leader>sh", "<cmd>split<CR>", { desc = "Horizontal split" })
map("n", "<leader>se", "<C-w>=", { desc = "Equalize splits" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close split" })

-- Resize windows with arrow keys
map("n", "<C-Up>", "<cmd>resize +2<CR>")
map("n", "<C-Down>", "<cmd>resize -2<CR>")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>")

-- Tabs
map("n", "<Tab>n", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<Tab>d", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<Tab>l", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<Tab>h", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- Terminal
map("n", "<leader>tt", "<cmd>botright split | resize 12 | terminal<CR>i", { desc = "Open terminal" })
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
map("t", "<C-h>", [[<C-\><C-n><C-w>h]])
map("t", "<C-j>", [[<C-\><C-n><C-w>j]])
map("t", "<C-k>", [[<C-\><C-n><C-w>k]])
map("t", "<C-l>", [[<C-\><C-n><C-w>l]])

-- Toggles
map("n", "<leader>uw", "<cmd>set wrap!<CR>", { desc = "Toggle wrap" })
map("n", "<leader>un", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative number" })
map("n", "<leader>us", "<cmd>set spell!<CR>", { desc = "Toggle spell check" })
