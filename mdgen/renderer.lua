local Tokens = require("mdgen.tokens")
local Helpers = require("mdgen.helpers")
local Typeinfo = require("mdgen.typeinfo")

---@class MDGen.TextRenderer
---Processes a stream of tokens and stores the intermediary state.
---@field lines string[] The lines rendered so far.
---@field indentstack string[] Stack of indent, can push/pop.
---@field next_indent string effective indent.
---@field textwidth number The textwidth of this renderer.
---@field current_line_len number The textwidth of this renderer.
---Renders markdown-formatted lines.
---@field n_virtual_linebreaks number Minimum number of linebreaks to insert
---before the next text-token.
---@field prev_token MDGen.Token? Previously encountered token, initially nil.
---@field pre_token_callbacks fun(next_token:MDGen.Token)[]
---Callbacks to execute before processing the next token.
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
		n_virtual_linebreaks = 0,
		prev_token = nil,
		pre_token_callbacks = {}
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
		if not (#self.lines == 1 and self.lines[1]:match("^%s*$")) then
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
		self:consume_pre_token_callbacks(token)
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
				self:append_tokens({
					-- surround the marker with data-tokens so tokens
					-- before/after it can check for its presence.
					Tokens.data({listmarker = true}),
					Tokens.combinable_linebreak(1),
					Tokens.fixed_text({list_marker(i)}),
					Tokens.data({listmarker = true})
				})
				self:push_indent(indent)
				self:append_tokens(item_tokens)
				self:pop_indent()
			end

			-- only insert the combinable linebreak if the next token is not a list-item
			self:add_pre_token_callback(function(next_token)
				if not (Tokens.is_data(next_token) and next_token.data.listmarker) then
					self:append_tokens({ Tokens.combinable_linebreak(2) })
				end
			end)
		elseif Tokens.is_combinable_linebreak(token) then
			self.n_virtual_linebreaks = math.max(token.n, self.n_virtual_linebreaks)
		elseif Tokens.is_prev_cb(token) then
			self:append_tokens(token.callback(self.prev_token))
		else
			-- DataToken lands here.
		end
		self.prev_token = token
	end
end

function TextRenderer:add_pre_token_callback(fn)
	table.insert(self.pre_token_callbacks, fn)
end

function TextRenderer:consume_pre_token_callbacks(next_token)
	local cbs = self.pre_token_callbacks
	-- clear before running callback, callback could call `append_tokens` and
	-- cause a loop.
	self.pre_token_callbacks = {}
	for _, cb in ipairs(cbs) do
		cb(next_token)
	end
end

local public_render_fn_names = { "append_tokens", "push_indent", "pop_indent" }

function TextRenderer:get_render_env()
	local env = {}

	for _, fname in ipairs(public_render_fn_names) do
		env[fname] = function(...)
			self[fname](self, ...)
		end
	end
	for fname, f in pairs(Helpers) do
		env[fname] = f
		if fname:match("_tokens$") then
			env[fname:gsub("_tokens$", "")] = function(...)
				self:append_tokens(f(...))
			end
		end
	end
	for fname, f in pairs(Typeinfo) do
		env[fname] = f
	end
	env.tokens = {}
	for fname, f in pairs(Tokens) do
		env.tokens[fname] = f
	end
	env.mode = Mode
	return env
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
