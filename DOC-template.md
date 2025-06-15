# Cat

This project models a cat. The cat can meow and eat, without limit.

* My doc:
  ````lua render_region
  list({list_type = "bulleted", items = {
      fn_doc_tokens({typename = "Cat", funcname = "meow"}),
      fn_doc_tokens({typename = "Cat", funcname = "eat"}),
      markdown_tokens([[
          ```lua
          print("lel")
          ```
      ]]),
      fn_doc_tokens({typename = "Cat", funcname = "enemies"}),
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
