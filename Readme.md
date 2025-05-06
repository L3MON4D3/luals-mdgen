# Usage

Generate documentation in markdown from a templated markdown file and
LuaCATS-annotations.

```bash
# generate documentation (do whenever the source has changed).
lua-language-server --configpath ./.luarc.doc.json --doc ./ --doc_out_path ./
nvim --clean --headless -l mdgen.lua <template-file> <doc.json> <output-file>
```

# Links
The source code for the doc-command is located
[here](https://github.com/LuaLS/lua-language-server/tree/master/script/cli/doc)
(In case we need some modifications).
[This issue](https://github.com/LuaLS/lua-language-server/issues/2997) shows how
to generate `doc.json` with only types of the current project.
