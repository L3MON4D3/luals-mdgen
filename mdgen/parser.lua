local Tokens = require("mdgen.tokens")

local M = {}

-- ASSUMPTIONS: markdown only contains
-- * plain text
-- * inline code
-- * links
-- * fenced code blocks
-- * lists

local parsers = {}

local function posbyte(_, _, byte)
	return byte
end

function parsers.paragraph(source, node)
	-- node should be like (paragraph (inline <actual content>)), drop the outer layer.
	local child1 = node:child(0)
	if not child1 then
		error("paragraph " .. vim.treesitter.get_node_text(node,source).. " is not like (paragraph (inline <actual content>)).")
	end
	node = child1

	-- continue with inline parsing:
	source = vim.treesitter.get_node_text(node, source)
	local parser = vim.treesitter.get_string_parser(source, "markdown_inline")
	parser:parse()
	node = parser:trees()[1]:root()

	local ast = {}

	local function append_text(from, to)
		-- append non-whitespace characters in-order.
		local unhandled_text = source:sub(from, to)
		for match in unhandled_text:gmatch("[^%s]+") do
			table.insert(ast, match)
		end
	end

	local current_from = posbyte(node:start())+1
	for _, named_child in ipairs(node:named_children()) do
		local named_start = posbyte(named_child:start())

		append_text(current_from, named_start)

		local node_parser = parsers[named_child:type()]
		if not node_parser then
			error("No parser for node-type " .. node:type() .. " in " .. vim.treesitter.get_node_text(node,source) .. ".")
		end
		vim.list_extend(ast, node_parser(source, named_child))

		current_from = posbyte(named_child:end_())+1
	end
	append_text(current_from, posbyte(node:end_()))

	return ast
end
function parsers.inline_link(source, node)
	return {vim.treesitter.get_node_text(node, source)}
end
function parsers.code_span(source, node)
	return {vim.treesitter.get_node_text(node, source)}
end
function parsers.hard_line_break()
	-- preserve hard line break in text.
	return { Tokens.fixed_text({"  ", ""}) }
end

function parsers.fenced_code_block(source, node)
	local lines = {""}
	-- starts at |```, ends at ```|.
	local block_text_start = posbyte(node:start())+1
	local block_text_end = nil
	for i = node:named_child_count()-1, 1, -1 do
		local potential_block_end = node:named_child(i)
		if potential_block_end:type() == "fenced_code_block_delimiter" then
			block_text_end = posbyte(potential_block_end:end_())
			break
		end
	end
	local block_text = source:sub(block_text_start, block_text_end)

	local split_text = vim.split(block_text, "\n", {plain=true, trimempty=false})
	local block_indent = split_text[#split_text]:match("(%s*)```")
	if not block_indent then
		error("Cannot parse " .. block_text .. ".")
	end

	for i = 2, #split_text do
		split_text[i] = split_text[i]:sub(#block_indent+1)
	end
	vim.list_extend(lines, split_text)

	-- append a final newline.
	table.insert(lines, "")

	return { Tokens.fixed_text(lines) }
end

local function ignore() return {} end
parsers.list_marker_star = ignore
parsers.list_marker_minus = ignore
parsers.list_marker_plus = ignore
parsers.list_marker_dot = ignore
parsers.list_marker_parenthesis = ignore

local marker_to_list_type = {
	list_marker_star = "bulleted",
	list_marker_minus = "bulleted",
	list_marker_plus = "bulleted",
	list_marker_dot = "numbered",
	list_marker_parenthesis = "numbered",
}

function parsers.list(source, node)
	local items = {}
	for i, item_node in ipairs(node:named_children()) do
		items[i] = parsers.top_level(source, item_node)
	end

	-- node = list(list_item(list_marker_* ...))
	local marker = node:named_child(0):named_child(0)

	return { Tokens.list(items, marker_to_list_type[marker:type()]) }
end

function parsers.top_level(source, tl_node)
	local tokens = {}
	for _, node in ipairs(tl_node:named_children()) do
		local node_parser = parsers[node:type()]
		if not node_parser then
			error("No parser for node-type " .. node:type() .. " in node ")
		end
		vim.list_extend(tokens, node_parser(source, node))
	end
	return tokens
end

---Parse a \n-concatenated block of markdown lines.
---@param lines string \n-concatenated lines.
---@return MDGen.Token[] tokens A somewhat reduced syntax tree.
function M.parse_markdown(lines)
	local parser = vim.treesitter.get_string_parser(lines, "markdown")
	parser:parse()
	local root = parser:trees()[1]:root()

	-- tree looks like (document (section <actual content>)) since we don't
	-- allow multiple sections for now.
	local section = root:child(0)
	if not section then
		error(("Error while parsing markdown %s: does not match `(document (section <actual content>))`."):format(lines))
	end

	local res = parsers.top_level(lines, section)
	parser:destroy()
	return res
end

return M
