return {
    'nvim-telescope/telescope.nvim',
    commit = '5255aa27c422de944791318024167ad5d40aad20', -- tag: v0.2.2
    dependencies = {
        {
            'nvim-lua/plenary.nvim',
            commit = '50012918b2fc8357b87cff2a7f7f0446e47da174', -- tag: v0.1.4
        },
        -- optional but recommended
        {
            'nvim-telescope/telescope-fzf-native.nvim',
            commit = 'b25b749b9db64d375d782094e2b9dce53ad53a40', -- no release tags, pinned to tested commit
            build = 'make',
        },
    },
    config = function()
        local builtin = require('telescope.builtin')
        vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
        vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Telescope live grep' })
        vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
        vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end
}
