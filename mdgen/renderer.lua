local Tokens = require("mdgen.tokens")
local Parser = require("mdgen.parser")
local Util = require("mdgen.util")
local Typeinfo = require("mdgen.typeinfo")

---@class MDGen.TextRenderer
---@field lines string[] The lines rendered so far.
---@field indentstack string[] Stack of indent, can push/pop.
---@field next_indent string effective indent.
---@field textwidth number The textwidth of this renderer.
---@field current_line_len number The textwidth of this renderer.
---Renders markdown-formatted lines.
---@field n_virtual_linebreaks number Minimum number of linebreaks to insert
---before the next text-token.
local TextRenderer = {}
TextRenderer.__index = TextRenderer

---@class MDGen.TextRendererOpts
---@field base_indent string Indent applied to all lines of this TextRenderer.
---@field textwidth number Maximum number of characters in a line. Does not
---handle unicode correctly.

---Create a new TextRenderer.
---@param opts MDGen.TextRendererOpts Init-options.
---@return MDGen.TextRenderer
function TextRenderer.new(opts)
	return setmetatable({
		textwidth = opts.textwidth,
		lines = {opts.base_indent},
		indentstack = {opts.base_indent},
		next_indent = opts.base_indent,
		current_line_len = #opts.base_indent,
		n_virtual_linebreaks = 0
	}, TextRenderer)
end

function TextRenderer:push_indent(indent)
	table.insert(self.indentstack, indent)
	self.next_indent = self.next_indent .. indent
end

function TextRenderer:pop_indent()
	if #self.indentstack == 1 then
		error("Cannot pop base-indent!")
	end

	local popped_indent = self.indentstack[#self.indentstack]
	self.indentstack[#self.indentstack] = nil

	self.next_indent = self.next_indent:sub(1, -#popped_indent-1)
end

function TextRenderer:insert_virtual_linebreaks()
	if self.n_virtual_linebreaks > 0 then
		-- there is always at least one line, but if it is empty, there is
		-- nothing to separate with these linebreaks => don't insert them, just
		-- clear n_virtual_linebreaks.
		if not (#self.lines == 1 and self.lines[1]:match("^%s+$")) then
			for _ = 1, self.n_virtual_linebreaks do
				table.insert(self.lines, self.next_indent)
			end
			self.current_line_len = #self.next_indent
		end
		self.n_virtual_linebreaks = 0
	end
end

---Append a list of tokens.
---@param tokens MDGen.Token[]
function TextRenderer:append_tokens(tokens)
	for _, token in ipairs(tokens) do
		if type(token) == "string" then
			self:insert_virtual_linebreaks()

			local sep = self.lines[#self.lines]:sub(-1, -1):match("[^%s]") and " " or ""

			local line_len = self.current_line_len + #sep + #token

			-- insert token into line if it fits below textwidth or if adding
			-- the token to the next line makes it as long as this line (this
			-- case actually occurs naturally when the first token after a `* `
			-- is very long)
			if line_len <= self.textwidth or #self.next_indent + #token == line_len then
				self.lines[#self.lines] = self.lines[#self.lines] .. sep .. token
				self.current_line_len = line_len
			else
				local new_line = self.next_indent .. token
				table.insert(self.lines, new_line)
				self.current_line_len = #new_line
			end
		elseif Tokens.is_fixed_text(token) then
			self:insert_virtual_linebreaks()

			self.lines[#self.lines] = self.lines[#self.lines] .. token.text[1]
			for i = 2, #token.text do
				table.insert(self.lines, self.next_indent .. token.text[i])
			end
			self.current_line_len = #self.lines[#self.lines]
		elseif Tokens.is_list(token) then
			local list_marker
			local indent
			if token.list_type == "numbered" then
				local max_num_width = #tostring(#token.items)
				list_marker = function(i)
					return string.format("%0" .. max_num_width .."d", i) .. ". "
				end
				-- list_marker looks like |100. |, make sure text is aligned
				-- below it.
				indent = (" "):rep(max_num_width+2)
			else
				list_marker = function() return "* " end
				indent = "  "
			end

			for i, item_tokens in ipairs(token.items) do
				self:append_tokens({Tokens.fixed_text({"", list_marker(i)})})
				self:push_indent(indent)
				self:append_tokens(item_tokens)
				self:pop_indent()
			end

			self:append_tokens({ Tokens.combinable_linebreak(2) })
		elseif Tokens.is_combinable_linebreak(token) then
			self.n_virtual_linebreaks = math.max(token.n, self.n_virtual_linebreaks)
		end
	end
end

---Generate a function-prototype string in markdown
---@param finfo MDGen.FuncInfo
local function prototype_string(typename, finfo)
	local fn_line = "`" .. typename .. ".".. finfo.name .. "("

	if #finfo.params > 0 then
		for _, param in ipairs(finfo.params) do
			fn_line = fn_line .. ("%s, "):format(param.name)
		end
		-- omit trailing ", ".
		fn_line = fn_line:sub(1,-3)
	end

	return fn_line .. ")`"
end

function TextRenderer:fn_doc(opts)
	vim.validate("funcname", opts.funcname, {"string"})
	vim.validate("typename", opts.typename, {"string"})

	local info = Typeinfo.funcinfo(opts.typename, opts.funcname)
	local tokens = { prototype_string(opts.typename, info) .. ":" }

	vim.list_extend(tokens, Parser.parse_markdown(info.description))

	local paramlist_items = {}
	for i, param in ipairs(info.params) do
		local param_tokens = {("`%s: %s`"):format(param.name, param.type)}
		vim.list_extend(param_tokens, Parser.parse_markdown(param.description))
		paramlist_items[i] = param_tokens
	end
	table.insert(tokens, Tokens.list(paramlist_items, "bulleted"))

	self:append_tokens(tokens)
end

function TextRenderer:newline()
	self:append_tokens({Tokens.fixed_text({"", ""})})
end

function TextRenderer:remove_tail_lines(n)
	for i = #self.lines-n+1, #self.lines do
		self.lines[i] = nil
	end
	self.current_line_len = #self.lines[#self.lines]
end

local public_render_fn_names = { "fn_doc", "newline", "remove_tail_lines" }

function TextRenderer:get_wrapped_render_fns()
	local wrapped_render_fns = {}
	for _, fname in ipairs(public_render_fn_names) do
		wrapped_render_fns[fname] = function(...)
			self[fname](self, ...)
		end
	end
	return wrapped_render_fns
end

function TextRenderer:get_final_lines()
	local lines_clean = {}
	for i, line in ipairs(self.lines) do
		if line:match("^%s+$") then
			lines_clean[i] = ""
		else
			lines_clean[i] = line
		end
	end

	return lines_clean
end

return TextRenderer
