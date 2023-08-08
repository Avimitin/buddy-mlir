{ buddy-mlir, stdenv }:
stdenv.mkDerivation {
  pname = "bert-mlir";
  version = "unstable-2023-07-07";
  src = ../examples/DLModel/Bert.mlir;
  dontUnpack = true;
  # TODO: add rv32-clang
  nativeBuildInputs = [
    buddy-mlir
  ];
  buddyOptArgs = [
    "--test-linalg-transform-patterns=test-generalize-pad-tensor"
    "--linalg-bufferize"
    "--convert-linalg-to-loops"
    "--func-bufferize"
    "--arith-bufferize"
    "--tensor-bufferize"
    "--finalizing-bufferize"
    "--convert-vector-to-scf"
    "--convert-scf-to-cf"
    "--expand-strided-metadata"
    "--lower-affine"
    "--convert-vector-to-llvm"
    "--memref-expand"
    "--arith-expand"
    "--convert-arith-to-llvm"
    "--finalize-memref-to-llvm"
    "--test-math-polynomial-approximation"
    "--convert-math-to-llvm"
    "--llvm-request-c-wrappers"
    "--convert-func-to-llvm"
    "--reconcile-unrealized-casts"
  ];
  buddyLlcArgs = [
    "--mtriple=riscv32"
    "--target-abi=ilp32"
    "--mattr=+m,+d,+v"
    "-riscv-v-vector-bits-min=128"
    "--filetype=asm"
  ];
  buildPhase = ''
    buddy-opt $src $buddyOptArgs -o bert-lowered.mlir
    buddy-translate bert-lowered.mlir --buddy-to-llvmir -o bert.llvmir
    buddy-llc bert.llvmir $buddyLlcArgs -o bert.asm
    # TODO: Compile the asm to elf
  '';

  installPhase = ''
    mkdir -p $out/bin $out/dist
    cp bert.elf $out/bin/bert
    cp bert-lowered.mlir bert.llvmir bert.asm $out/dist
  '';
}
