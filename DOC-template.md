# Cat

This project models a cat. The cat can meow and eat, without limit.

* My doc:
  ````lua render_region
  local medialinks = {
    eating_cat = "https://balmesvet.com/wp-content/uploads/2025/05/4.jpg"
  }

  list({list_type = "bulleted", items = {
      fn_doc_tokens({typename = "Cat", funcname = "meow"}),
      fn_doc_tokens({typename = "Cat", funcname = "eat", media_mapping = medialinks}),
      markdown_tokens([[
          ```lua
          print("lel")
          ```
      ]]),
      fn_doc_tokens({typename = "Cat", funcname = "enemies", type_expand =
      { CatEnemiesOpts = {explain_type = "CatEnemiesOpts"}, CatEnemiesExtraOpts = {explain_type = "CatEnemiesExtraOpts"} } }),
      markdown_tokens([[
          lel lol  
          lul
          ```lua
          print("lel")
          ```
      ]]),
  }})
  markdown([[
    ```lua
    print("lol")
    ```
  ]])
  ````

# Other Animals?

Only cat for now.
