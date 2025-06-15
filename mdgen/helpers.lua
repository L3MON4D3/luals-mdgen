local Tokens = require("mdgen.tokens")
local Typeinfo = require("mdgen.typeinfo")
local Parser = require("mdgen.parser")
local Str = require("mdgen.str")

local M = {}

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

function M.fn_doc_tokens(opts)
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
