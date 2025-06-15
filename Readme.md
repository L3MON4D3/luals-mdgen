# Usage

Generate documentation in markdown from a templated markdown file and
LuaCATS-annotations.

```bash
# generate documentation (do whenever the source has changed).
emmylua_doc_cli -f json -i test_project -o ./ 
nvim --clean --headless -l mdgen.lua <template-file> <output-file>
```
