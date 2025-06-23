local M = {}

---In-place dedents strings in lines.
---@param lines string[].
---@param from integer First line to consider
---@param to integer Last line to consider
function M.dedent(lines, from, to)
	if #lines > 0 then
		local ind_size = math.huge
		for i = from,to do
			local _, i2 = lines[i]:find("^%s*[^%s]")
			if i2 and i2 < ind_size then
				ind_size = i2
			end
		end
		for i = from, to do
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
	local split_lines = vim.split(lines, "\n", {plain=true, trimempty = false})

	if options.trim_empty then
		if split_lines[1]:match("^%s*$") then
			table.remove(split_lines, 1)
		end
		if #split_lines > 0 and split_lines[#split_lines]:match("^%s*$") then
			split_lines[#split_lines] = nil
		end
	end

	if options.dedent then
		M.dedent(split_lines, 1, #split_lines)
	end

	return table.concat(split_lines, "\n")
end

return M
