{
  description = "Nix flake for buddy-mlir development";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let overlay = import ./overlay.nix;
    in flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ overlay ];
        };
        binaries_to_env = with builtins;
          bins:
            listToAttrs (
              map
                (x: {
                   name = (pkgs.lib.toUpper (replaceStrings [ "-" ] [ "_" ] x));
                   value = "${pkgs.buddy-mlir}/bin/${x}";
                 })
              bins
            );
      in {
        devShells.ci = pkgs.mkShell {
          buildInputs = with pkgs; [ buddy-mlir libspike ];

          # Overwrite the makefile value
          env = (binaries_to_env [
            "mlir-opt"
            "mlir-translate"
            "mlir-cpu-runner"
            "buddy-opt"
            "buddy-translate"
            "buddy-llc"
            "llc"
          ]) // {};
        };

        packages.buddy-mlir = pkgs.callPackage ./nix/buddy.nix { };

        formatter = pkgs.writeScriptBin "format-all" ''
          #!${pkgs.bash}/bin/bash
          ${pkgs.findutils}/bin/find . \
            -name '*.nix' \
            -exec ${pkgs.nixfmt}/bin/nixfmt {} +
        '';
      });
}
