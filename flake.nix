{
  description = "A Malbolge interpreter, written entirely in Nix.";

  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = { self, flake-schemas, nixpkgs }:
    let
      pkgs = import <nixpkgs> {};
      lib = pkgs.lib;
      malbolgeLength = 59048;
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
      stdout = x : builtins.trace "${toString x}" (x);
      filein = x : (builtins.readFile x);
      fileinChars = x : builtins.stringToCharacters (filein x);
      fileinInts = x : map (y : lib.strings.charToInt y) (fileinChars x);
      fileinCharsNoSpace = x : builtins.filter (y : y != " ") (fileinChars x);
      fileinIntsNoSpace = x : map (y : lib.strings.charToInt y) (fileinCharsNoSpace x); 
      mem = builtins.genList(x : { a = false; b = false; }) malbolgeLength;
      path = "./main.mb";
      stdin_path = "./stdin.txt";
      # main.mbstdin is a stdin replicator
      stdin_parsed = fileinInts stdin_path;
      fileLength = builtins.stringLength (fileinCharsNoSpace path);
      rawFileLength = builtins.stringLength (fileinChars path);
      initialMemory = builtins.genList(i : (if i < fileLength then (builtins.elemAt (fileinIntsNoSpace path) i) else 0)) malbolgeLength;
      transformedMemory = lib.lists.imap0 (i : v : if i < fileLength then v else (op (builtins.elemAt transformedMemory (i - 1)) (builtins.elemAt transformedMemory (i - 2)))) initialMemory;
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
          index = lib.trivial.mod (charValue - 33 + c) 94;
        in
        builtins.elemAt xlat1List index;
      # determine element at index 1-94 for xlat2
      mutate = charValue: builtins.elemAt xlat2List (charValue - 33);
      pvm = index : builtins.elemAt (lib.lists.imap0 (i : v : if v > 33 && v < 127 then (decode v i) else 0) (fileinChars path)) index; # is 0 messing us up?
      validMap = lib.lists.imap0 (i : v : ((pvm i) == "j" || (pvm i) == "i" || (pvm i) == "*" || (pvm i) == "p" || (pvm i) == "<" || (pvm i) == "/" || (pvm i) == "v" || (pvm i) == "o")) (builtins.genList (i : i) rawFileLength);
      # checks if the file is valid
      validFile = builtins.foldl' (acc : x : acc && x) true validMap;
      # a, c, d storage
      acid = [0 0 0];
      # TODO: write exec function @Sahanav
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
