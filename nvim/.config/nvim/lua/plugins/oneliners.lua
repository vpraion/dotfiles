return {
    {
	-- Helps with ssh tunneling and copying to clipboard
	'ojroques/vim-oscyank',
	commit = "d67d76b2f19b868b70a1cf33a779d71dc092cb30", -- not a release tag
    },
    {
	-- Git plugin
	'tpope/vim-fugitive',
	commit = "96c1009fcf8ce60161cc938d149dd5a66d570756", -- tag 3.7
    },
    {
	-- Show CSS Colors
	'brenoprata10/nvim-highlight-colors',
	commit = "e4c7af0211866162d999ce0bdd6a029302e19139", -- not a release tag
	config = function()
	    require('nvim-highlight-colors').setup({})
	end
    },
}
