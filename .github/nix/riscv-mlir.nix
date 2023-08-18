{ cmake, ninja, python3, fetchFromGitHub, stdenv, riscv-gnu-toolchain }:
let
  llvmSrc = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
    # The LLVM rev buddy-mlir currently using have cross-compiling issue,
    # so we are using different rev here. See issue #152 for defails.
    rev = "8a4e3675d88ecd0413d89dea1e3578a4696b05da";
    hash = "sha256-ZubkH/gkjRJhVmmNnRkUmdO/F58UGYdMFeOE6s/sl2g=";
  };
  host-llvm = stdenv.mkDerivation {
    pname = "cross-llvm";
    version = "unstable-2023-05-02";
    requiredSystemFeatures = [ "big-parallel" ];
    nativeBuildInputs = [ cmake ninja python3 ];
    src = llvmSrc;
    cmakeDir = "../llvm";
    cmakeFlags = [
      "-DLLVM_ENABLE_PROJECTS=clang;mlir"
      "-DLLVM_TARGETS_TO_BUILD=host;RISCV"
    ];
    checkTarget = "check-clang check-mlir";
  };
in
stdenv.mkDerivation {
  pname = "riscv-mlir";
  version = "unstable-2023-05-02";
  requiredSystemFeatures = [ "big-parallel" ];
  nativeBuildInputs = [ cmake ninja python3 ];
  src = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
    # The LLVM rev buddy-mlir currently using have cross-compiling issue,
    # so we are using different rev here. See issue #152 for defails.
    rev = "8a4e3675d88ecd0413d89dea1e3578a4696b05da";
    hash = "sha256-ZubkH/gkjRJhVmmNnRkUmdO/F58UGYdMFeOE6s/sl2g=";
  };

  preConfigure = ''
    cmakeFlagsArray+=(
      -DCMAKE_C_FLAGS="--target=riscv64-unknonw-linux-gnu --sysroot=${riscv-gnu-toolchain}/sysroot --gcc-toolchain=${riscv-gnu-toolchain}"
      -DCMAKE_CXX_FLAGS="--target=riscv64-unknonw-linux-gnu --sysroot=${riscv-gnu-toolchain}/sysroot --gcc-toolchain=${riscv-gnu-toolchain}"
    )
  '';
  cmakeDir = "../llvm";
  cmakeFlags = [
    "-DLLVM_ENABLE_PROJECTS=mlir"
    "-DCMAKE_CROSSCOMPILING=True"
    "-DLLVM_TARGET_ARCH=RISCV64"
    "-DLLVM_TARGETS_TO_BUILD=RISCV"
    "-DLLVM_BUILD_EXAMPLES=OFF"
    "-DLLVM_ENABLE_BINDINGS=OFF"
    "-DLLVM_ENABLE_OCAMLDOC=OFF"
    "-DLLVM_NATIVE_ARCH=RISCV"
    "-DLLVM_HOST_TRIPLE=riscv64-unknown-linux-gnu"
    "-DLLVM_DEFAULT_TARGET_TRIPLE=riscv64-unknown-linux-gnu"
    "-DCMAKE_C_COMPILER=${host-llvm}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${host-llvm}/bin/clang++"
    "-DMLIR_TABLEGEN=${host-llvm}/bin/mlir-tblgen"
    "-DLLVM_TABLEGEN=${host-llvm}/bin/llvm-tblgen"
    "-DMLIR_PDLL_TABLEGEN=${host-llvm}/bin/mlir-pdll"
    "-DMLIR_LINALG_ODS_YAML_GEN=${host-llvm}/bin/mlir-linalg-ods-yaml-gen"
    "-DLLVM_ENABLE_ZSTD=OFF"
  ];
  checkTarget = "check-mlir";
}
