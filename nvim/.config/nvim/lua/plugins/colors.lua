local function enable_transparency()
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
end
return {
    {
        "folke/tokyonight.nvim",
        commit = "545d72cde6400835d895160ecb5853874fd5156d", -- tag: v4.14.1
        config = function()
            vim.cmd.colorscheme "tokyonight"
            enable_transparency()
        end
    },
    {
        "nvim-lualine/lualine.nvim",
        commit = "221ce6b2d999187044529f49da6554a92f740a96", -- no release tags, pinned to tested commit
        dependencies = {
            {
                "nvim-tree/nvim-web-devicons",
                commit = "21417212f640a1dad28a1408f04468819848f5e7", -- tag: nerd-v3.2-compat
            },
        },
        opts = {
            theme = 'tokyonight'
        }
    }
}
