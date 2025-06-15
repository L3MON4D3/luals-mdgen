-- some global arguments.
local template_fname = arg[1]
local out_fname = arg[2]

local TextRenderer = require("mdgen.renderer")

local template_lines = vim.fn.readfile(template_fname)
local res_lines = {}

local i = 1
while i <= #template_lines do
	local line_i = template_lines[i]

	local matched_indent = line_i:match("(%s*)```lua render_region")
	if matched_indent then
		local funcstr = ""

		for j = i+1, #template_lines do
			local line_j = template_lines[j]

			if line_j:match("%s*```") then
				-- we have found a render_region, parse the lua-lines in it and
				-- execute them.
				local f, err = loadstring(funcstr)
				if not f then
					error("Error in region from line " .. i .. " to line " .. j .. ": " .. err)
				end

				local renderer = TextRenderer.new({
					textwidth = 20,
					base_indent = matched_indent
				})

				local f_mt = setmetatable(renderer:get_wrapped_render_fns(), {__index = _G})

				setfenv(f, f_mt)
				f()
				vim.list_extend(res_lines, renderer:get_final_lines())

				i = j + 1

				goto continue_outer
			else
				-- don't append the final, matching line.
				-- add \n for better readability.
				funcstr = funcstr .. line_j .. "\n"
			end
		end
		error("Could not find the end of region starting at line " .. i)
	else
		table.insert(res_lines, line_i)
		i = i+1
	end
	::continue_outer::
end

vim.fn.writefile(res_lines, out_fname)
