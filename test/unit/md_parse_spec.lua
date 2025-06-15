describe("parse", function()
	it("complex", function()
		local parser = require("mdgen.parser")
		local text = [[
How much to eat.  
The cat [lel lel](lol) may eat a `lel lol lul` lot. Call like
```lua
 Cat:eat(5)
```
May be any food a cat does not die from.
* food1:
  ```lua
  print("lel")
  ```
  asdf
* food2
* food3
  ```lua
  asdf asdf
  asdf
  asasdf
  ```
qwer

1. sadf
2. qwer
]]

		local codeblock_pre = {
				type = "prev_cb",
				-- some function
				callback = parser.__pre_codeblock_cb
			}
		local codeblock_post = {
				n = 1, type = "combinable_linebreak"
			}
		local res = {
			"How", "much", "to", "eat.",
			{
				text = { "  " }, type = "fixed_text"
			},
			{
				n = 1, type = "combinable_linebreak"
			},
			"The", "cat", "[lel lel](lol)", "may", "eat", "a", "`lel lol lul`", "lot.", "Call", "like",
			codeblock_pre,
			{
				text = { "```lua", " Cat:eat(5)", "```" },
				type = "fixed_text"
			},
			codeblock_post,
			"May", "be", "any", "food", "a", "cat", "does", "not", "die", "from.",
			{
				items = {
					{
						"food1:",
						codeblock_pre,
						{
							type = "fixed_text",
							text = { "```lua", 'print("lel")', "```" }
						},
						codeblock_post,
						"asdf"
					},
					{ "food2" },
					{
						"food3",
						codeblock_pre,
						{
							text = { "```lua", "asdf asdf", "asdf", "asasdf", "```" },
							type = "fixed_text"
						},
						codeblock_post,
					}
				},
				list_type = "bulleted",
				type = "list"
			},
			"qwer",
			{
				items = {{"sadf"}, {"qwer"}},
				type = "list",
				list_type = "numbered"
			} }
		local parsed = parser.parse_markdown(text)
		-- replace functions with 
		assert.are.same(res, parsed)
	end)
end)
