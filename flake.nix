{
  description = "A Malbolge interpreter, written entirely in Nix.";

  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";

    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*";
  };

  outputs = { self, flake-schemas, nixpkgs }:
    let
      pkgs = import <nixpkgs> {};
      lib = pkgs.lib;
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
      stdout = x : builtins.trace "${toString x}" (x);
      filein = x : (builtins.readFile x);
      # Trits have a and b, because you need 2 bits to hold a trit.
      # When working with trits, you must input two booleans.
      # The sequence ab has a as MSB.
      trit_creator = x : (y : if (builtins.typeOf x == "bool" && builtins.typeOf y == "bool" && !(x && y)) then { a = x; b = y; } else {a = false; b = false;});
      trit_updator = memory : new_trit : index : (lib.lists.imap0(i : v : if i == index then new_trit else v) memory);
      mem = builtins.genList(x : { a = false; b = false; }) 59049;
    in {

      schemas = flake-schemas.schemas;

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {

          packages = with pkgs; [
            nixpkgs-fmt
          ];
        };
      });
    };


}
