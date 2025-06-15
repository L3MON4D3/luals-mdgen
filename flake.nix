{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    emmylua-analyzer-rust.url = "github:EmmyLuaLs/emmylua-analyzer-rust";

    # Probably won't have to update this, hardcode ref.
    nlua = {
      url = "https://raw.githubusercontent.com/mfussenegger/nlua/8a2d76043d94ed4130ae703f13f393bb9132d259/nlua";
      flake = false;
    };
  };
  outputs = {self, nixpkgs, flake-utils, emmylua-analyzer-rust, nlua }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        rt_deps = with pkgs; [
          neovim
          jq
        ];
        test_deps = with pkgs; [
          luajitPackages.busted
          emmylua-analyzer-rust.outputs.packages.${system}.emmylua_doc_cli
          # requires that nvim is in PATH!! (always the case for us)
          (pkgs.concatTextFile {
            name = "nlua";
            files = [ nlua ];
            executable = true;
            destination = "/bin/nlua";
          })
        ];
      in {
        packages.default = pkgs.writeShellApplication {
          name = "luals-mdgen";
          runtimeInputs = rt_deps;
          text = ''
            LUA_PATH="${./.}/?.lua;$LUA_PATH" nvim -u NONE --clean --headless -l ${./mdgen.lua} "$@"
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            just
          ] ++ rt_deps ++ test_deps;
        };
      }
    );
}
