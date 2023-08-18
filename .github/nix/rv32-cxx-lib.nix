{ llvmPackages_14, cmake, python3, ninja, glibc_multi, fetchFromGitHub }:
let
  pname = "rv32-cxx-lib";
  version = "unstable-2023-05-02";
  src = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
    rev = "8a4e3675d88ecd0413d89dea1e3578a4696b05da";
    sha256 = "sha256-ZubkH/gkjRJhVmmNnRkUmdO/F58UGYdMFeOE6s/sl2g=";
  };
  mkDerivation = llvmPackages_14.stdenv.mkDerivation;
in
llvmPackages_14.stdenv.mkDerivation {
  sourceRoot = "${src.name}/runtimes";
  inherit src version pname;
  nativeBuildInputs = [ cmake ninja python3 glibc_multi ];
  cmakeFlags = [
    "-DLLVM_ENABLE_RUNTIMES=libcxx;libcxxabi;libunwind"
    # "-DLIBCXX_CXX_ABI=libcxxabi"
    # "-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON"
    "-DLLVM_TARGET_ARCH=RISCV32"
    "-DLLVM_TARGETS_TO_BUILD=RISCV"
    "-DLLVM_RUNTIME_TARGET=riscv32-unknown-linux-gnu"
    # "-DLLVM_DEFAULT_TARGET_TRIPLE=riscv32-unknown-linux-gnu"
    # "-DLIBCXXABI_USE_LLVM_UNWINDER=ON"
    # "-DLIBCXX_INCLUDE_TESTS=OFF"
    # "-DLIBCXX_INCLUDE_BENCHMARKS=OFF"
    # "-DCMAKE_SYSTEM_NAME=Generic"
    # "-DCMAKE_SYSTEM_PROCESSOR=riscv32"
    # "-DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY"
    # "-DCMAKE_SIZEOF_VOID_P=8"
    # "-DCMAKE_ASM_COMPILER_TARGET=riscv32-none-elf"
    # "-DCMAKE_C_COMPILER_TARGET=riscv32-none-elf"
    # "-DCMAKE_CXX_COMPILER_TARGET=riscv32-none-elf"
    # "-DCMAKE_C_COMPILER=clang"
    # "-DCMAKE_CXX_COMPILER=clang++"
    # "-Wno-dev"
  ];
  CMAKE_C_FLAGS = "-nodefaultlibs -fno-exceptions -mno-relax -Wno-macro-redefined -fPIC";
}
