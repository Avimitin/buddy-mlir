{ cmake, ninja, python3, fetchFromGitHub, stdenv, llvmForDev, riscv-gnu-toolchain}:
let
  llvmSrc = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
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
      "-DLLVM_ENABLE_PROJECTS=clang"
      "-DLLVM_TARGETS_TO_BUILD=host;RISCV"
    ];
    checkTarget = "check-clang";
  };
in
llvmForDev.stdenv.mkDerivation rec {
  pname = "riscv-cxx-runtime";
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
      -DCMAKE_C_FLAGS="--gcc-toolchain=${riscv-gnu-toolchain}"
      -DCMAKE_CXX_FLAGS="--gcc-toolchain=${riscv-gnu-toolchain}"
    )
  '';

  cmakeDir = "../runtimes";
  _targetTriple = "riscv32-unknown-linux-gnu";
  cmakeFlags = [
    "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind"
    "-DCMAKE_ASM_COMPILER_TARGET=${_targetTriple}"
    "-DCMAKE_SYSROOT=${riscv-gnu-toolchain}/sysroot"
    "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON"
    "-DLIBUNWIND_ENABLE_STATIC=ON"
    "-DLIBCXX_ENABLE_EXCEPTIONS=OFF"
    "-DLIBCXX_INCLUDE_TESTS=OFF"
    "-DCMAKE_CROSSCOMPILING=True"
    "-DLLVM_TARGETS_TO_BUILD=RISCV32"
    "-DLLVM_DEFAULT_TARGET_TRIPLE=${_targetTriple}"
    "-DCMAKE_C_COMPILER=${host-llvm}/bin/clang"
    "-DCMAKE_CXX_COMPILER=${host-llvm}/bin/clang++"
    "-DCMAKE_C_COMPILER_TARGET=${_targetTriple}"
    "-DCMAKE_CXX_COMPILER_TARGET=${_targetTriple}"
  ];
#checkTarget = "check-runtimes";
}
