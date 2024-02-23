local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

local p = function(value)
	print(vim.inspect(value))
end

local t = function(node)
	p(ts.get_node_text(node, 0))
end

local qs = [[  ]]

local parser = parsers.get_parser()
local tree = parser:parse()[1]
local root = tree:root()
local lang = parser:lang()

--@param child TSNode
--@param result TSNode[] [child, parent, grandparent, ....]
local function get_parents(child, results)
	local type = child:type()
	assert(type == "property_identifier")
	local parent = child:parent()
	assert(parent:type() == "pair")
	parent = parent:parent()
	assert(parent:type() == "object")
	local sib = parent:prev_named_sibling()

	if sib:type() == "property_identifier" then
		get_parents(sib, results)
	end

	table.insert(results, sib)
end

--@param node TSNode
local function logme(node)
	-- local query = ts.query.parse(lang, "(property_identifier) @prop ")
	--@type table<integer, TSNode>
	local prop_nodes = {}
	get_parents(node, prop_nodes)
	table.insert(prop_nodes, node)
	local node_texts = {}
	for _, node in ipairs(prop_nodes) do
		table.insert(node_texts, ts.get_node_text(node, 0))
	end
	local text = table.concat(node_texts, ".")
	local s = "console.log('" .. text .. ":', " .. text .. ");"

	local first = prop_nodes[1]
	local declarator = first:parent()
	local stop = declarator:end_() + 1

	local curr_line = vim.api.nvim_buf_get_lines(0, stop, stop + 1, false)[1]

	vim.api.nvim_buf_set_lines(0, stop, stop + 1, false, { s, "", curr_line })
end

local function console()
	local curr_node = ts.get_node()
	logme(curr_node)
end

vim.api.nvim_create_user_command("console", console, {})
vim.keymap.set("n", "hc", console)

-- lua vim.keymap.set('n', '<leader>c', ':luafile ./console.log.nvim/lua/console_log.lua<cr>', { silent = true, noremap = true })
--  .
--   .
--    .,,,,
