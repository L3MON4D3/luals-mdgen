gen_test_doc:
	emmylua_doc_cli -f json -i test_project -o ./ 
	LUA_PATH="./?.lua;$LUA_PATH" nvim --clean --headless -l mdgen.lua DOC-template.md DOC.md

test:
	busted --lua nlua --lpath "./?.lua" test/
