gen_doc:
	lua-language-server --configpath ./.luarc.doc.json --doc ./ --doc_out_path ./
	nvim --clean --headless -l mdgen.lua DOC-template.md doc.json DOC.md
