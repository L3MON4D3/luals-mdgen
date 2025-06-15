local M = {}

---In-place dedents strings in lines.
---@param lines string[].
local function dedent(lines)
	if #lines > 0 then
		local ind_size = math.huge
		for i, _ in ipairs(lines) do
			local i1, i2 = lines[i]:find("^%s*[^%s]")
			if i1 and i2 < ind_size then
				ind_size = i2
			end
		end
		for i, _ in ipairs(lines) do
			lines[i] = lines[i]:sub(ind_size, -1)
		end
	end
end

---Applies opts to lines.
---lines is modified in-place.
---@param lines string
---@param options table, required, can have values:
---  - trim_empty: removes empty first and last lines.
---  - dedent: removes indent common to all lines.
---  - indent_string: an unit indent at beginning of each line after applying `dedent`, default empty string (disabled)
function M.process_multiline(lines, options)
	local split_lines = vim.split(lines, "\n")

	if options.trim_empty then
		if split_lines[1]:match("^%s*$") then
			table.remove(split_lines, 1)
		end
		if #split_lines > 0 and split_lines[#split_lines]:match("^%s*$") then
			split_lines[#split_lines] = nil
		end
	end

	if options.dedent then
		dedent(split_lines)
	end

	return table.concat(split_lines, "\n")
end

return M
