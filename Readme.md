# Usage

Generate documentation in markdown from a templated markdown file and
LuaCATS-annotations.

```bash
# generate documentation (do whenever the source has changed).
emmylua_doc_cli -f json -i test_project -o ./ 
nvim --clean --headless -l mdgen.lua <template-file> <output-file>
```

For an example see the input in [`DOC-template.md`](https://github.com/L3MON4D3/luals-mdgen/blob/main/DOC-template.md?plain=1) and [`test_project/project.lua`](https://github.com/L3MON4D3/luals-mdgen/blob/main/test_project/project.lua) and the result in [`DOC.md`](https://github.com/L3MON4D3/luals-mdgen/blob/main/DOC.md).
