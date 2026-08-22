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
      trit_access = memory : index : builtins.elemAt memory index;
      mem = builtins.genList(x : { a = false; b = false; }) 59049;
      y = f : (x : f (x x)) (x : f (x x));
      xlat1 =
        "+b(29e*j1VMEKLyC})8&m#~W>qxdRp0wkrUo[D7,XTcA\"lI"
        + ".v%{gJh4G\\-=O@5`_3i<?Z';FNQuY]szf$!BS/|t:Pn6^Ha";
    
      xlat2 =
        "5z]&gqtyfr$(we4{WP)H-Zn,[%\\3dL+Q;>U!pJS72FhOA1C"
        + "B6v^=I_0/8|jsb9m<.TVac`uY*MK'X~xDl}REokN:#?G\"i@";
    
      # create character arrays
      xlat1List = builtins.stringToCharacters xlat1;
      xlat2List = builtins.stringToCharacters xlat2;
    
      # determine element at index 1-94 for xlat1
      decode =
        charValue: c:
        let
          index = builtins.mod (charValue - 33 + c) 94;
        in
        builtins.elemAt xlat1List index;
    
      # determine element at index 1-94 for xlat2
      mutate = charValue: builtins.elemAt xlat2List (charValue - 33);
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
