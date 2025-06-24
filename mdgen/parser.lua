local Tokens = require("mdgen.tokens")
local Str = require("mdgen.str")

local M = {}

-- ASSUMPTIONS: markdown only contains
-- * plain text
-- * inline code
-- * links
-- * fenced code blocks
-- * lists

local parsers = {}
local inline_parsers = {}

local function posbyte(_, _, byte)
	return byte
end

function parsers.paragraph(source, node, opts)
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

	local ast = {
		Tokens.prev_token_cb(function(prev_token)
			if prev_token and Tokens.is_data(prev_token) and prev_token.data.paragraph_end then
				return { Tokens.combinable_linebreak(2) }
			else
				return {}
			end
		end)
	}

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

		local node_parser = inline_parsers[named_child:type()]
		if not node_parser then
			error("No parser for node-type " .. node:type() .. " in " .. vim.treesitter.get_node_text(node,source) .. ".")
		end
		local node_tokens, tokens_end = node_parser(source, named_child, opts)
		vim.list_extend(ast, node_tokens)

		current_from = tokens_end+1
	end
	append_text(current_from, posbyte(node:end_()))
	table.insert(ast, Tokens.data({paragraph_end = true}))

	return ast
end

-- these return the position the text should continue at, in addition to the
-- tokens.

---@param source string
---@param node TSNode Node corresponding to an inline_link.
---@param opts MDGen.Opts.ParseMarkdown
---@return MDGen.Token[] Tokens
---@return integer byte_pos_end End-position of the extracted region. This is
---required because we may grab more than just the node, and the caller has to
---know about this, and not re-parse these characters.
function inline_parsers.inline_link(source, node, opts)
	local node_text = vim.treesitter.get_node_text(node, source)
	-- these should exist!
	local link_name = vim.treesitter.get_node_text((node:named_child(0) --[[@as TSNode]]), source)
	local link_dest = vim.treesitter.get_node_text((node:named_child(1) --[[@as TSNode]]), source)

	local link_relative_file, link_target_section = link_dest:match("^(%.[^#]+)%#(.*)$")

	local file_newrel = nil
	-- try to find the relative path from the generated markdown to the
	-- link-destionation, so we can insert a relative link again.
	if link_relative_file and opts.srcfile_abs then
		local link_dest_abs = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(opts.srcfile_abs), link_relative_file))
		-- if link_dest_abs exactly matches the output-file, the link is to a
		-- section in the generated markdown. We thus don't need a path and can
		-- just use the #<sectionname> as link-destination.
		if link_dest_abs == Outfile then
			file_newrel = ""
		else
			local common_base = vim.fs.dirname(Outfile)
			local outfile_to_common_base = "./"
			-- this loop cannot run endlessly because every path only has a
			-- finite number of parent-directories, and once those are exhausted
			-- and .dirname yields "/", relpath has to succeed.
			while true do
				local doc_destfile_relpath = vim.fs.relpath(common_base, link_dest_abs)
				if doc_destfile_relpath then
					-- outfile_relpath_prefix may be like `./../../`, simplify
					-- that.
					file_newrel = vim.fs.normalize(vim.fs.joinpath(outfile_to_common_base, doc_destfile_relpath))
					break
				else
					common_base = vim.fs.dirname(common_base)
					outfile_to_common_base = vim.fs.joinpath(outfile_to_common_base, "..")
				end
			end
		end
	end
	if file_newrel ~= nil then
		link_dest = file_newrel .. "#" .. link_target_section
	end
	node_text = ("[%s](%s)"):format(link_name, link_dest)

	local tokens_end = posbyte(node:end_())
	local non_whitespace_from, non_whitespace_to, non_whitespace_text = source:find("([^%s]+)", tokens_end+1)

	if non_whitespace_from == tokens_end+1 then
		node_text = node_text .. non_whitespace_text
		-- if non_whitespace_from was non-nil, non_whitespace_to is too.
		tokens_end = non_whitespace_to --[[@as integer]]
	end
	return {node_text}, tokens_end
end
function inline_parsers.code_span(source, node)
	local node_text = vim.treesitter.get_node_text(node, source)
	local tokens_end = posbyte(node:end_())

	local non_whitespace_from, non_whitespace_to, non_whitespace_text = source:find("([^%s]+)", tokens_end+1)

	if non_whitespace_from == tokens_end+1 then
		node_text = node_text .. non_whitespace_text
		tokens_end = non_whitespace_to
	end
	return {node_text}, tokens_end
end

function inline_parsers.hard_line_break(_, node)
	-- preserve hard line break in text.
	return { Tokens.fixed_text({"  "}), Tokens.combinable_linebreak(1) }, posbyte(node:end_())
end

local function pre_codeblock_cb(prev_token)
	if not prev_token or (Tokens.is_data(prev_token) and prev_token.data.listmarker) then
		return {}
	end
	return { Tokens.combinable_linebreak(1) }
end
-- expose so busted can use it for are.same-checks.
M.__pre_codeblock_cb = pre_codeblock_cb

function parsers.fenced_code_block(source, node)
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

	for i = 1, #split_text do
		split_text[i] = split_text[i]:sub(#block_indent+1)
	end

	Str.dedent(split_text, 2, #split_text-1)

	return { Tokens.prev_token_cb(pre_codeblock_cb), Tokens.fixed_text(split_text), Tokens.combinable_linebreak(1) }
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

---Parse markdown-list.
---@param source string Source-text.
---@param node TSNode
---@param opts MDGen.Opts.ParseMarkdown
---@return [MDGen.ListToken]
function parsers.list(source, node, opts)
	local items = {}
	for i, item_node in ipairs(node:named_children()) do
		items[i] = parsers.top_level(source, item_node, opts)
	end

	-- node = list(list_item(list_marker_* ...))
	local marker = node:named_child(0):named_child(0)
	if not marker then
		error("list " .. vim.treesitter.get_node_text(node,source).. " is not like list(list_item(list_marker_* ...)).")
	end

	return { Tokens.list(items, marker_to_list_type[marker:type()]) }
end

---Parse top-level node. This can be a document or a list-item.
---@param source string Source-text.
---@param tl_node TSNode
---@param opts MDGen.Opts.ParseMarkdown
---@return MDGen.Token[]
function parsers.top_level(source, tl_node, opts)
	local tokens = {}
	for _, node in ipairs(tl_node:named_children()) do
		local node_parser = parsers[node:type()]
		if not node_parser then
			error("No parser for node-type " .. node:type() .. " in node ")
		end
		vim.list_extend(tokens, node_parser(source, node, opts))
	end
	return tokens
end

---@class MDGen.Opts.ParseMarkdown
---@field srcfile_abs string? Absolute path to source-file.

---Parse a \n-concatenated block of markdown lines.
---@param lines string|MDGen.Description \n-concatenated lines or `MDGen.Description` object.
---@param opts MDGen.Opts.ParseMarkdown? Additional, optional arguments
---@return MDGen.Token[] tokens A somewhat reduced syntax tree.
function M.parse_markdown(lines, opts)
	opts = opts or {}
	if type(lines) ~= "string" and lines.src and lines.content then
		lines = lines --[[@as MDGen.Description]]
		opts.srcfile_abs = lines.src
		lines = lines.content
	end
	lines = lines --[[@as string]]

	local parser = vim.treesitter.get_string_parser(lines, "markdown")
	parser:parse()
	local root = parser:trees()[1]:root()

	-- tree looks like (document (section <actual content>)) since we don't
	-- allow multiple sections for now.
	local section = root:child(0)
	if not section then
		error(("Error while parsing markdown %s: does not match `(document (section <actual content>))`."):format(lines))
	end

	local res = parsers.top_level(lines, section, opts)
	parser:destroy()
	return res
end

return M
