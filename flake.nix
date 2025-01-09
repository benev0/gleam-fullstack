{
  description = "Development environment Gleam";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs,  ...}:
    let
      system = "x86_64-linux";
      matcha = pkgs.rustPlatform.buildRustPackage rec {
        pname = "matcha";
        version = "0.19.0";

        src = pkgs.fetchFromGitHub {
          owner = "michaeljones";
          repo = pname;
          rev = "137c325cf153fbbfb80768fd5a526f09fb2c35eb";
          hash = "sha256-Yz1eGbE97NsEA/mKlo1y19w8Dp0r+548XeSeCfFoRFQ=";
        };
        # cargoHash = lib.fakeHash;
        cargoHash = "sha256-7wFu0B39mIp54I0PA0F/IIdu7oF976cotsISnEU+oEc=";
      };
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default =
        pkgs.mkShell {
          buildInputs = [
            matcha
            pkgs.erlang_27
            pkgs.gleam
            pkgs.rebar3
            pkgs.elixir
            pkgs.glas
            pkgs.vscode-extensions.gleam.gleam
          ];
          shellHook = ''
            echo "shell ready"
            gleam --version
          '';
        };
    };
}
