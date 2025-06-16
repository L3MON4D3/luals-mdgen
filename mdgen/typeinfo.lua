local Util = require("mdgen.util")

local json_name = "./doc.json"

local json_content = table.concat(vim.fn.readfile(json_name))
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

---@class MDGen.ParamInfo
---@field name string
---@field type string?
---@field description string? \n-concatenated

---@class MDGen.FuncInfo
---@field name string
---@field description string? \n-concatenated
---@field params MDGen.ParamInfo[]

function M.funcinfo(typename, funcname)
	local raw_fdoc = doc_index[typename].members_by_name[funcname]

	local params = {}
	for i, param in ipairs(raw_fdoc.params) do
		params[i] = {
			name = param.name,
			type = Util.ternary(param.typ ~= vim.NIL, param.typ, nil),
			description = Util.ternary(param.desc ~= vim.NIL, param.desc, nil)
		} --[[@as MDGen.ParamInfo]]
	end
	return {
		name = raw_fdoc.name,
		description = Util.ternary(raw_fdoc.description ~= vim.NIL, raw_fdoc.description, nil),
		params = params
	} --[[@as MDGen.FuncInfo]]
end

--for now these two are identical.
---@alias MDGen.MemberInfo MDGen.ParamInfo

---@class MDGen.ClassInfo
---@field members MDGen.MemberInfo[]

function M.classinfo(typename)
	local raw_classdoc = doc_index[typename].ref
	local members = {}
	for i, member in ipairs(raw_classdoc.members) do
		members[i] = {
			name = member.name,
			type = member.typ,
			description = Util.ternary(member.description ~= vim.NIL, member.description, nil)
		} --[[@as MDGen.MemberInfo]]
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
