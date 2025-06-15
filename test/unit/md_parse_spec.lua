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

		local res = { "How", "much", "to", "eat.", { text = { "  ", "" }, type = "fixed_text" }, "The", "cat", "[lel lel](lol)", "may", "eat", "a", "`lel lol lul`", "lot.", "Call", "like", {
			text = { "", "```lua", " Cat:eat(5)", "```", "" },
			type = "fixed_text"
		  }, "May", "be", "any", "food", "a", "cat", "does", "not", "die", "from.", {
			items = { { "food1:", {
				  text = { "", "```lua", 'print("lel")', "```", "" },
				  type = "fixed_text"
				}, "asdf" }, { "food2" }, { "food3", {
				  text = { "", "```lua", "asdf asdf", "asdf", "asasdf", "```", "" },
				  type = "fixed_text"
				} } },
			list_type = "bulleted",
			type = "list"
		  }, "qwer", {
		  	items = {{"sadf"}, {"qwer"}},
		  	type = "list",
		  	list_type = "numbered"
		  } }

		assert.are.same(res, parser.parse_markdown(text))
	end)
end)
