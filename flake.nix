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
    let
      myOverlay = import ./overlay.nix;
      overlays = [ vector.overlays.default myOverlay ];
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs { inherit system overlays; };
          mkLLVMShell =
            pkgs.mkShell.override { stdenv = pkgs.llvmForDev.stdenv; };
        in
        {
          devShells.ci = mkLLVMShell {
            buildInputs = with pkgs; [
              spike
              riscv-pk
              dtc
              rv32-clangxx
              riscv-gnu-toolchain
              (writeShellScriptBin "run-bert" ''
                spike --isa=RV64GCV "$@" ${riscv-pk}/bin/pk ${bert}/bin/sentiment-classification || \
                  echo -e "\n\nFail to run, try\n    spike -d ${riscv-pk}/bin/pk $BERT_BIN 2>error.log\nto get error instruction"
              '')
              (writeShellScriptBin "qemu-rv64" ''
                LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${riscv-cxx-runtime}/lib \
                  ${qemu}/bin/qemu-riscv64 -L ${riscv-gnu-toolchain}/sysroot \
                    -cpu rv64,x-v=true,vlen=128 "$@"
              '')
            ];

            env = {
              BERT_BIN = "${pkgs.bert}/bin/sentiment-classification";
            };
          };

          packages.bert = pkgs.callPackage ./.github/nix/bert.nix { };
          packages.riscv-pk = pkgs.callPackage ./.github/nix/riscv-pk.nix { };
          packages.riscv-cxx-runtime = pkgs.callPackage ./.github/nix/riscv-cxx-runtime.nix {  };

          formatter = pkgs.nixpkgs-fmt;
        })
    # Export our overlay in case somebody need them
    // { overlays.default = myOverlay; };
}
