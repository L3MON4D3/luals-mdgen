---@alias MDGen.Token (string|MDGen.ListToken|MDGen.FixedTextToken|MDGen.CombinableLinebreakToken)

local M = {}

---@alias MDGen.ListType "bulleted"|"numbered"

---@class MDGen.ListToken
---@field type "list"
---@field list_type MDGen.ListType
---@field items MDGen.Token[][] first list represents list-items, second content of each item.

---Create a new ListToken.
---@param items MDGen.Token[][]
---@param type MDGen.ListType
---@return MDGen.ListToken
function M.list(items, type)
	return {
		type = "list",
		list_type = type,
		items = items
	} --[[@as MDGen.ListToken]]
end

function M.is_list(token)
	return token.type == "list"
end

---@class MDGen.FixedTextToken
---Represents text that has to be rendered verbatim. For example, code-blocks
---may not be reflowed.
---@field type "fixed_text"
---@field text string[]

function M.fixed_text(text)
	return {
		type = "fixed_text",
		text = text
	} --[[@as MDGen.FixedTextToken]]
end

function M.is_fixed_text(token)
	return token.type == "fixed_text"
end

---@class MDGen.CombinableLinebreakToken
---Represents a minimum number of linebreaks between the previous and next
---non-CombinableLinebreakToken.
---@field type "combinable_linebreak"
---@field n number Number of linebreaks.

function M.combinable_linebreak(n)
	return {
		type = "combinable_linebreak",
		n = n
	} --[[@as MDGen.CombinableLinebreakToken]]
end

function M.is_combinable_linebreak(token)
	return token.type == "combinable_linebreak"
end

return M
