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
			local p_id = param.name
			-- Append a `?` to the param-name if it is optional. Effectively
			-- communicates which parameters are important and which are less
			-- important.
			-- if this parameter is optional, it should be possible to write it
			-- s.t. the last character of the type is a ?.
			if param.type and param.type:sub(-1,-1) == "?" then
				p_id = p_id .. "?"
			end
			fn_line = fn_line .. ("%s, "):format(p_id)
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
---@field type_expand table<string, MDGen.ExpandSpec>
---@field media_mapping MDGen.MediaMapping
---@field pre_list_linebreak boolean Whether to add an empty line before lists.

---Generate a markdown-list from a list of fields of a class.
---@param fields MDGen.MemberInfo[]
---@param opts MDGen.Opts.FieldListToMdlist Additional, named arguments.
---@return MDGen.ListToken
local function fieldlist_to_mdlist(fields, opts)
	local list_items = {}

	for i, field in ipairs(fields) do
		local field_id = "`" .. field.name
		if field.type then
			if field.type:sub(-1,-1) == "?" then
				field_id = field_id .. "?"
			end
			field_id = field_id .. ": " .. field.type
		end
		field_id = field_id .. "`"
		local param_tokens = {field_id}
		if field.description then
			vim.list_extend(param_tokens, Parser.parse_markdown(field.description, {
				media_mapping = opts.media_mapping
			}))
		end

		if field.type and opts.type_expand[field.type] then
			vim.list_extend(param_tokens, {
				Tokens.fixed_text({"  "}), Tokens.combinable_linebreak(1),
				"Valid", "keys", "are:" })

			local class_info = Typeinfo.classinfo(opts.type_expand[field.type].explain_type)
			if not class_info then
				error("explain_type for " .. field.type .. " was " .. opts.type_expand[field.type].explain_type .. " but no information could be found on that type.")
			end
			if opts.pre_list_linebreak then
				table.insert(param_tokens, Tokens.combinable_linebreak(2))
			end
			table.insert(param_tokens, fieldlist_to_mdlist(class_info.members, opts))
		end

		list_items[i] = param_tokens
	end

	return Tokens.list(list_items, "bulleted")
end

--- Generate a markdown-list from function-parameters.
---@param items MDGen.ParamInfo[]
---@param opts MDGen.Opts.FieldListToMdlist
local function paramlist_to_mdlist(items, opts)
	local paramlist_items = {}
	local additional_info = false
	for i, param in ipairs(items) do
		if param.description or param.type then
			additional_info = true
		end

		local param_id = "`" .. param.name
		if param.type then
			if param.type:sub(-1,-1) == "?" then
				param_id = param_id .. "?"
			end
			param_id = param_id .. ": " .. param.type
		end
		param_id = param_id .. "`"
		local param_tokens = {param_id}
		if param.description then
			vim.list_extend(param_tokens, Parser.parse_markdown(param.description, {
				media_mapping = opts.media_mapping
			}))
		end

		if param.type and opts.type_expand[param.type] then
			vim.list_extend(param_tokens, {
				Tokens.fixed_text({"  "}), Tokens.combinable_linebreak(1),
				"Valid", "keys", "are:" })

			local class_info = Typeinfo.classinfo(opts.type_expand[param.type].explain_type)
			if not class_info then
				error("explain_type for " .. param.type .. " was " .. opts.type_expand[param.type].explain_type .. " but no information could be found on that type.")
			end
			if opts.pre_list_linebreak then
				table.insert(param_tokens, Tokens.combinable_linebreak(2))
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

function M.prototype_string(opts)
	vim.validate("funcname", opts.funcname, {"string"})
	vim.validate("typename", opts.typename, {"string"})
	vim.validate("display_fname", opts.display_fname, {"string", "nil"})

	local display_fname = opts.display_fname or opts.typename .. "." .. opts.funcname

	local func_info = Typeinfo.funcinfo(opts.typename, opts.funcname)
	return prototype_string(display_fname, func_info)
end

function M.func_info_tokens(opts)
	vim.validate("funcname", opts.funcname, {"string"})
	vim.validate("typename", opts.typename, {"string"})
	vim.validate("type_expand", opts.type_expand, {"table", "nil"})
	vim.validate("media_mapping", opts.media_mapping, {"table", "nil"})
	vim.validate("pre_list_linebreak", opts.pre_list_linebreak, {"boolean", "nil"})

	local type_expand = opts.type_expand or {}
	local pre_list_linebreak = vim.F.if_nil(opts.pre_list_linebreak, false)
	local media_mapping = opts.media_mapping or {}

	local info = Typeinfo.funcinfo(opts.typename, opts.funcname)
	local param_list = paramlist_to_mdlist(info.params, {
		type_expand = type_expand,
		pre_list_linebreak = pre_list_linebreak,
		media_mapping = media_mapping
	})
	local return_list = returnlist_to_mdlist(info.returns)

	if param_list == nil and info.description == nil and return_list == nil then
		-- if there is no additional info, return an empty list.
		return {}
	end

	local tokens = {}
	if info.description then
		vim.list_extend(tokens, Parser.parse_markdown(info.description, {
			media_mapping = media_mapping
		}))
	end
	if param_list then
		if opts.pre_list_linebreak then
			table.insert(tokens, Tokens.combinable_linebreak(2))
		end
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
			Tokens.combinable_linebreak(2),
			"This", "function", "returns:",
			Util.ternary(pre_list_linebreak, Tokens.combinable_linebreak(2), nil),
			return_list
		})
	end

	return tokens
end

function M.fn_doc_tokens(opts)
	local prot_string = M.prototype_string(opts)
	local fi_tokens = M.func_info_tokens(opts)
	if #fi_tokens > 0 then
		prot_string = prot_string .. ":"
	end
	local tokens = {prot_string}
	vim.list_extend(tokens, fi_tokens)
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
