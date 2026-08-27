{
  description = "A Malbolge interpreter, written entirely in Nix.";

  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, flake-schemas, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" "aarch64-linux" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
            pkgs = nixpkgs.legacyPackages.${system}; # use flake pkgs import method instead of legacy
      });
      lib = builtins.break(nixpkgs.lib);
    in {
      schemas = flake-schemas.schemas;

      lib.interpreter = import ./malbolge.nix;

       apps = forEachSupportedSystem ({ pkgs }: {
         default = {
	   type = "app";
	   program = "${pkgs.writeShellScriptBin "malbolge-nix" ''
	     FILE="''${1:-./main.mb}
	     ${pkgs.nix}/bin/nix eval --raw --argstr path "$FILE" --file ${./malbolge.nix}"
	    ''}/bin/malbolge-nix";
     	 };
       });

      devShells = forEachSupportedSystem (
        { pkgs }: {
          default = pkgs.mkShell {
            packages = with pkgs; [
              nixpkgs-fmt
            ];
          };
        }
      );
    };
}
