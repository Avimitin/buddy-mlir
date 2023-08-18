final: prev: {
  bert = final.callPackage ./.github/nix/bert.nix { };
  riscv-gnu-toolchain = final.callPackage ./.github/nix/riscv-gnu-toolchain.nix { };
  riscv-cxx-runtime = final.callPackage ./.github/nix/riscv-cxx-runtime.nix { };
  # The one existing in nixpkgs is not fit our need
  riscv-pk = final.callPackage ./.github/nix/riscv-pk.nix { };
  spike = final.callPackage ./.github/nix/spike.nix { };
  qemu = final.callPackage ./.github/nix/qemu.nix { };
  rv32-clangxx = final.callPackage
    (
      { my-cc-wrapper, rv32-compilerrt, rv32-musl, writeShellScriptBin }:
      writeShellScriptBin "clang++-rv32" ''
        ${my-cc-wrapper}/bin/clang++ --target=riscv32 -fuse-ld=lld -L${rv32-compilerrt}/lib/riscv32 -L${rv32-musl}/lib "$@"
      ''
    )
    { };
}
