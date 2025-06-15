local M = {}

-- bool and xxx else yyy is weird..
function M.ternary(bool, if_, else_)
	if bool then
		return if_
	else
		return else_
	end
end

return M
