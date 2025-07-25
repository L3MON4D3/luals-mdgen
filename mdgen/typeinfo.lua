local Util = require("mdgen.util")

local json_content = table.concat(vim.fn.readfile(JSONFile))
local doc = vim.json.decode(json_content)

---@class MDGen.TypeIndex
---@field ref table The original table from doc.json.
---@field members_by_name table<string, table> Map member-names to their
---documentation.

---@alias MDGen.DocIndex table<string, MDGen.TypeIndex>
---Map type- and function-names to their respective doc.json-table.


local doc_index = (function()
	local index = {}
	for _, type in ipairs(doc.types) do
		local members_by_name = {}
		for _, member in ipairs(type.members) do
			members_by_name[member.name] = member
		end

		index[type.name] = {
			ref = type,
			members_by_name = members_by_name
		}
	end

	return index
end)() --[[@as MDGen.DocIndex]]

local M = {}

---@class MDGen.Description
---@field content string \n-concatenated
---@field src string File that contains this description

---@class MDGen.ParamInfo
---@field name string
---@field type string?
---@field description MDGen.Description?

---@class MDGen.ReturnInfo
---@field type string
---@field name string?
---@field description MDGen.Description?

---@class MDGen.FuncInfo
---@field name string
---@field description MDGen.Description? \n-concatenated
---@field params MDGen.ParamInfo[]
---@field returns MDGen.ReturnInfo[]

function M.funcinfo(typename, funcname)
	local raw_fdoc = doc_index[typename].members_by_name[funcname]

	local params = {}
	for i, param in ipairs(raw_fdoc.params) do
		params[i] = {
			name = param.name,
			type = Util.ternary(param.typ ~= vim.NIL, param.typ, nil),
			description = Util.ternary(param.desc ~= vim.NIL, {content = param.desc, src = raw_fdoc.loc.file} --[[@as MDGen.Description]], nil)
		} --[[@as MDGen.ParamInfo]]
	end
	local retvals = {}
	for i, param in ipairs(raw_fdoc.returns) do
		retvals[i] = {
			name = Util.ternary(param.name ~= vim.NIL and param.name ~= "_", param.name, nil),
			type = param.typ,
			description = Util.ternary(param.desc ~= vim.NIL, {content = param.desc, src = raw_fdoc.loc.file} --[[@as MDGen.Description]], nil)
		} --[[@as MDGen.ReturnInfo]]
	end
	-- remove trailing nil-returns.
	-- Mainly for clearing the table for functions that don't return anything,
	-- but there seems to be no reason for including trailing nil's in general.
	for i = #retvals, 1, -1 do
		if retvals[i].type == "nil" then
			retvals[i] = nil
		else
			break
		end
	end

	return {
		name = raw_fdoc.name,
		description = Util.ternary(raw_fdoc.description ~= vim.NIL, {content = raw_fdoc.description, src = raw_fdoc.loc.file} --[[@as MDGen.Description]], nil),
		params = params,
		returns = retvals
	} --[[@as MDGen.FuncInfo]]
end

--for now these two are identical.
---@alias MDGen.MemberInfo MDGen.ParamInfo

---@class MDGen.ClassInfo
---@field members MDGen.MemberInfo[]

---Find info on some class.
---@param typename string Name of the class.
---@return MDGen.ClassInfo? class_info Information on the queried class.
function M.classinfo(typename)
	if not doc_index[typename] then
		return nil
	end
	local raw_classdoc = doc_index[typename].ref

	local members = {}
	-- track member names so we can use the most-specific member in case of
	-- duplicates.
	local member_names = {}
	for _, member in ipairs(raw_classdoc.members) do
		member_names[member.name] = true
		table.insert(members, {
			name = member.name,
			type = member.typ,
			description = Util.ternary(member.description ~= vim.NIL, {content = member.description, src = member.loc.file} --[[@as MDGen.Description]], nil)
		} --[[@as MDGen.MemberInfo]])
	end
	for _, basename in ipairs(raw_classdoc.bases) do
		local baseinfo = M.classinfo(basename)
		if not baseinfo then
			error("Could not find base-class " .. basename)
		end
		for _, member in ipairs(baseinfo.members) do
			if not member_names[member.name] then
				table.insert(members, member)
			end
		end
	end
	return {members = members} --[[@as MDGen.ClassInfo]]
end

function M.fnames(typename)
	local raw_classdoc = doc_index[typename].ref

	local functions = {}
	for _, member in ipairs(raw_classdoc.members) do
		if member.type == "fn" then
			table.insert(functions, member.name)
		end
	end
	return functions
end

return M
