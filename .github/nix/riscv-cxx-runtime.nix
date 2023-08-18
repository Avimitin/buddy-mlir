{ cmake, ninja, python3, fetchFromGitHub, stdenv, llvmPackages_16, glibc_multi }:
let
  llvmSrc = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
    rev = "8a4e3675d88ecd0413d89dea1e3578a4696b05da";
    hash = "sha256-ZubkH/gkjRJhVmmNnRkUmdO/F58UGYdMFeOE6s/sl2g=";
  };
  cross-llvm = stdenv.mkDerivation {
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
llvmPackages_16.stdenv.mkDerivation rec {
  pname = "riscv-cxx-runtime";
  version = "unstable-2023-05-02";
  requiredSystemFeatures = [ "big-parallel" ];
  nativeBuildInputs = [ cmake ninja python3 ];
  # required for gnu/stubs-32.h
  buildInputs = [ glibc_multi ];
  src = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
    rev = "8a4e3675d88ecd0413d89dea1e3578a4696b05da";
    hash = "sha256-ZubkH/gkjRJhVmmNnRkUmdO/F58UGYdMFeOE6s/sl2g=";
  };

  cmakeDir = "../runtimes";
  _targetTriple = "riscv32-unknown-linux-elf";
  cmakeFlags = [
    # common
    "-DLLVM_ENABLE_RUNTIMES=libunwind"

    # libcxx
    "-DLIBCXX_INCLUDE_TESTS=OFF"
    #"-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON"
    #"-DLIBCXX_ENABLE_EXCEPTIONS=OFF"

    # libunwind
    "-DLIBUNWIND_ENABLE_STATIC=ON"
    # Required because compiler doesn't have exception support
    "-DLIBUNWIND_ENABLE_SHARED=OFF"
    #"-DLIBUNWIND_USE_COMPILER_RT=ON"

    # riscv related
    "-DCMAKE_ASM_COMPILER_TARGET=${_targetTriple}"
    "-DCMAKE_CROSSCOMPILING=True"
#"-DLLVM_TARGETS_TO_BUILD=RISCV32"
    "-DLLVM_DEFAULT_TARGET_TRIPLE=${_targetTriple}"

    # Do not perform compile test
#"-DCMAKE_C_COMPILER=${cross-llvm}/bin/clang"
#    "-DCMAKE_CXX_COMPILER=${cross-llvm}/bin/clang++"
    "-DCMAKE_C_COMPILER_WORKS=ON"
    "-DCMAKE_CXX_COMPILER_WORKS=ON"
    "-DCMAKE_C_COMPILER_TARGET=${_targetTriple}"
    "-DCMAKE_CXX_COMPILER_TARGET=${_targetTriple}"
  ];
#CMAKE_CXX_FLAGS = "-mfloat-abi=soft";
#checkTarget = "check-runtimes";
}
