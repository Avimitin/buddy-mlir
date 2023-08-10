{
  description = "Nix flake for buddy-mlir development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # Use the already configured overlay from vector repo.
    vector = {
      url = "github:sequencer/vector";
      # Replace the nixpkgs source to this flake, to avoid problem caused by different versions of nixpkgs.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, vector, flake-utils }:
    let overlays = [ vector.overlays.default ];
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system overlays; };
        binaries_to_env = with builtins;
          with pkgs;
          bins:
          listToAttrs (map (x: {
            name = (lib.toUpper (replaceStrings [ "-" ] [ "_" ] x));
            value = "${buddy-mlir}/bin/${x}";
          }) bins);
        mkLLVMShell =
          pkgs.mkShell.override { stdenv = pkgs.llvmForDev.stdenv; };
      in {
        devShells.ci = mkLLVMShell {
          buildInputs = with pkgs; [ buddy-mlir libspike rv32-clang ];

          # Overwrite the makefile value
          env = (binaries_to_env [
            "mlir-opt"
            "mlir-translate"
            "mlir-cpu-runner"
            "buddy-opt"
            "buddy-translate"
            "buddy-llc"
            "llc"
          ]) // { };
        };

        formatter = with pkgs;
          writeScriptBin "format-all" ''
            #!${bash}/bin/bash
            ${findutils}/bin/find . \
              -name '*.nix' \
              -exec ${pkgs.nixfmt}/bin/nixfmt {} +
          '';
      });
}
