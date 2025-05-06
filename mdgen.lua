-- some global arguments.
local template_fname = arg[1]
local json_name = arg[2]
local out_fname = arg[3]

---
--- Utility functions
---
local func_filter = [[.[] | select(.name == "%s" and .type == "type").fields| .[] | select(.name == "%s")]]
local function get_function_info(typename, funcname)
	local cmd = {"jq", func_filter:format(typename, funcname), json_name}
	local res = vim.system(cmd, {text=true}):wait()
	if res.stderr ~= "" then
		error("Error while running jq: " .. res.stderr)
	end
	if res.stdout == "" then
		error("jq invocation " .. vim.inspect(cmd) .. " returned an empty string.")
	end

	return vim.json.decode(res.stdout)
end

---
--- Render functions.
---
local render_fns = {}

local function render_fn_line(typename, funcname, args)
	local fn_line = "`" .. typename .. "." .. funcname .. "("

	if #args > 0 then
		for _, arg in ipairs(args) do
			fn_line = fn_line .. ("%s:%s, "):format(arg.name, arg.view)
		end
		-- omit trailing ", ".
		fn_line = fn_line:sub(1,-3)
	end
	return fn_line .. ")`"
end
local function render_arg_doc(args)
	local lines = {}

	for _, arg in ipairs(args) do
		local rawdesc = vim.split(arg.rawdesc or "", "\n")
		-- only respect the first line of rawdesc for now.
		table.insert(lines, ("* `%s: %s` %s"):format(arg.name, arg.view, rawdesc[1]))
	end

	return lines
end

function render_fns.render_fn_doc(opts)
	vim.validate("funcname", opts.funcname, {"string"})
	vim.validate("typename", opts.typename, {"string"})

	local info = get_function_info(opts.typename, opts.funcname)

	local lines = {}
	table.insert(lines, render_fn_line(opts.typename, opts.funcname, info.extends.args))
	vim.list_extend(lines, vim.split(info.rawdesc, "\n"))
	vim.list_extend(lines, render_arg_doc(info.extends.args))

	return lines
end

function render_fns.render_raw(text)
	return text
end


local template_lines = vim.fn.readfile(template_fname)
local res_lines = {}

local i = 1
while i <= #template_lines do
	local line_i = template_lines[i]

	if line_i:match("%s*```lua render_region") then
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

				local rendered_lines = {}

				-- add these into the fenv of the loaded function.
				-- Create here so we can have them append to the current
				-- `rendered_lines`.
				local wrapped_render_fns = {}
				for name, fn in pairs(render_fns) do
					wrapped_render_fns[name] = function(...)
						vim.list_extend(rendered_lines, fn(...))
					end
				end
				local f_mt = setmetatable(wrapped_render_fns, {__index = _G})

				setfenv(f, f_mt)
				f()
				vim.list_extend(res_lines, rendered_lines)

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
