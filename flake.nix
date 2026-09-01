{
  description = "A Malbolge interpreter, written entirely in Nix.";

  inputs = {
    flake-schemas.url = "https://flakehub.com/f/DeterminateSystems/flake-schemas/*";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
  default =
    let
      runner = pkgs.writeShellScriptBin "malbolge-nix" ''
        FILE="$(${pkgs.coreutils}/bin/realpath "''${1:-./main.mb}")"
        export MALBOLGE_FILE="$FILE"

        exec ${pkgs.nix}/bin/nix eval \
          --show-trace \
	  --impure \
          --json \
          --expr '
            let
              pkgs = import ${nixpkgs} {
                system = "${pkgs.system}";
              };

              interpreter = import ${./malbolge.nix} {
                inherit pkgs;
                lib = pkgs.lib;
                path = builtins.toPath (
                  builtins.getEnv "MALBOLGE_FILE"
                );
              };
            in
              interpreter.p
          '
      '';
    in
    {
      type = "app";
      program = "${runner}/bin/malbolge-nix";
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
