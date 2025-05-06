{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs = {self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShell = pkgs.mkShell {
          packages = with pkgs; [
            # important: need a version with https://github.com/LuaLS/lua-language-server/issues/2997
            lua-language-server
            # (pkgs.writeShellScriptBin "neovim-fixed" "exec -a $0 ${neovim}/bin/nvim $@")
            neovim
            bashInteractive
          ];
        };
      }
    );
}
