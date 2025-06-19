local Tokens = require("mdgen.tokens")
local Typeinfo = require("mdgen.typeinfo")
local Parser = require("mdgen.parser")
local Str = require("mdgen.str")
local Util = require("mdgen.util")

local M = {}

---Generate a function-prototype string in markdown
---@param finfo MDGen.FuncInfo
local function prototype_string(display_fname, finfo)
	local fn_line = "`" .. display_fname .. "("

	if #finfo.params > 0 then
		for _, param in ipairs(finfo.params) do
			fn_line = fn_line .. ("%s, "):format(param.name)
		end
		-- omit trailing ", ".
		fn_line = fn_line:sub(1,-3)
	end
	fn_line = fn_line .. ")"
	if #finfo.returns > 0 then
		fn_line = fn_line .. ": "
		for _, retval in ipairs(finfo.returns) do
			fn_line = fn_line .. ("%s, "):format(retval.type)
		end
		-- omit trailing ", ".
		fn_line = fn_line:sub(1,-3)
	end

	return fn_line .. "`"
end

---@class MDGen.ExpandSpec
---@field explain_type string Description of which type to insert at this
---position.

---@class MDGen.Opts.FieldListToMdlist
---@field opts_expand table<string, MDGen.ExpandSpec>

---Generate a markdown-list from a list of fields of a class.
---@param fields MDGen.MemberInfo[]
---@param opts MDGen.Opts.FieldListToMdlist Additional, optional arguments
---@return MDGen.ListToken
local function fieldlist_to_mdlist(fields, opts)
	local list_items = {}

	for i, field in ipairs(fields) do
		local field_id = "`" .. field.name
		if field.type then
			field_id = field_id .. ": " .. field.type
		end
		field_id = field_id .. "`"
		local param_tokens = {field_id}
		if field.description then
			vim.list_extend(param_tokens, Parser.parse_markdown(field.description))
		end

		if field.type and opts.opts_expand[field.type] then
			vim.list_extend(param_tokens, {
				Tokens.fixed_text({"  "}), Tokens.combinable_linebreak(1),
				"Valid", "keys", "are:" })

			local class_info = Typeinfo.classinfo(opts.opts_expand[field.type].explain_type)
			if not class_info then
				error("explain_type for " .. field.type .. " was " .. opts.opts_expand[field.type].explain_type .. " but no information could be found on that type.")
			end
			table.insert(param_tokens, fieldlist_to_mdlist(class_info.members, opts))
		end

		list_items[i] = param_tokens
	end

	return Tokens.list(list_items, "bulleted")
end
local function paramlist_to_mdlist(items, opts)
	local paramlist_items = {}
	local additional_info = false
	for i, param in ipairs(items) do
		if param.description or param.type then
			additional_info = true
		end

		local param_id = "`" .. param.name
		if param.type then
			param_id = param_id .. ": " .. param.type
		end
		param_id = param_id .. "`"
		local param_tokens = {param_id}
		if param.description then
			vim.list_extend(param_tokens, Parser.parse_markdown(param.description))
		end

		if param.type and opts.opts_expand[param.type] then
			vim.list_extend(param_tokens, {
				Tokens.fixed_text({"  "}), Tokens.combinable_linebreak(1),
				"Valid", "keys", "are:" })

			local class_info = Typeinfo.classinfo(opts.opts_expand[param.type].explain_type)
			if not class_info then
				error("explain_type for " .. param.type .. " was " .. opts.opts_expand[param.type].explain_type .. " but no information could be found on that type.")
			end
			table.insert(param_tokens, fieldlist_to_mdlist(class_info.members, opts))
		end

		paramlist_items[i] = param_tokens
	end

	if additional_info then
		return Tokens.list(paramlist_items, "bulleted")
	else
		return nil
	end
end

local function returnlist_to_mdlist(items)
	local returnlist_items = {}
	local additional_info = false
	for i, retval in ipairs(items) do
		if retval.name or retval.description then
			additional_info = true
		end

		local retval_id = "`"
		if retval.name then
			retval_id = retval_id .. retval.name .. ": "
		end
		retval_id = retval_id .. retval.type .. "`"
		local retval_tokens = {retval_id}

		if retval.description then
			vim.list_extend(retval_tokens, Parser.parse_markdown(retval.description))
		end

		returnlist_items[i] = retval_tokens
	end
	if additional_info then
		return Tokens.list(returnlist_items, "bulleted")
	else
		return nil
	end
end

function M.fn_doc_tokens(opts)
	vim.validate("funcname", opts.funcname, {"string"})
	vim.validate("typename", opts.typename, {"string"})
	vim.validate("opts_expand", opts.opts_expand, {"table", "nil"})
	vim.validate("display_fname", opts.display_fname, {"string", "nil"})

	local opts_expand = opts.opts_expand or {}
	local display_fname = opts.display_fname or opts.typename .. "." .. opts.funcname

	local info = Typeinfo.funcinfo(opts.typename, opts.funcname)
	local param_list = paramlist_to_mdlist(info.params, {opts_expand = opts_expand})
	local return_list = returnlist_to_mdlist(info.returns)

	local tokens = {
		-- only insert `:` if there is something after the prototype.
		prototype_string(display_fname, info) .. Util.ternary(param_list ~= nil or info.description ~= nil or return_list ~= nil, ":", ""),
	}
	if info.description then
		vim.list_extend(tokens, Parser.parse_markdown(info.description))
	end
	if param_list then
		table.insert(tokens, param_list)
	end
	if return_list then
		if info.description and not param_list then
			-- in this case, a linebreak between the function-description and
			-- the next short sentence seems sensible.
			vim.list_extend(tokens, {
				Tokens.fixed_text({"  "}),
				Tokens.combinable_linebreak(1)
			})
		end
		vim.list_extend(tokens, {
			"This", "function", "returns:",
			return_list
		})
	end

	return tokens
end

function M.list_tokens(opts)
	vim.validate("list_type", opts.list_type, {"string"})
	vim.validate("items", opts.items, {"table"})

	return {Tokens.list(opts.items, opts.list_type)}
end

function M.markdown_tokens(text)
	vim.validate("text", text, {"string"})
	return Parser.parse_markdown(Str.process_multiline(text, {dedent = true, trim_empty = true}))
end

return M
