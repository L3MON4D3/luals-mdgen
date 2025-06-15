---@alias MDGen.Token (string|MDGen.ListToken|MDGen.FixedTextToken)

---@class MDGen.ListToken
---@field type "list"
---@field items MDGen.Token[][] first list represents list-items, second content of each item.

---@class MDGen.FixedTextToken
---Represents text that has to be rendered verbatim. For example, code-blocks
---may not be reflowed.
---@field type "fixed_text"
---@field text string[]

return {
	list = function(items)
		return {
			type = "list",
			items = items
		} --[[@as MDGen.ListToken]]
	end,
	is_list = function(token)
		return token.type == "list"
	end,
	fixed_text = function(text)
		return {
			type = "fixed_text",
			text = text
		} --[[@as MDGen.FixedTextToken]]
	end,
	is_fixed_text = function(token)
		return token.type == "fixed_text"
	end,
}
