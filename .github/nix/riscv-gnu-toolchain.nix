{ fetchFromGitHub, stdenv, curl, texinfo, bison, flex, gmp, mpfr, libmpc, python3, perl, flock, expat }:
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
stdenv.mkDerivation rec {
  pname = "riscv-gnu-toolchain";
  version = "rvv-next-2022-11-12";
  src = fetchFromGitHub {
    owner = "riscv-collab";
    repo = pname;
    rev = "642d90ffcd8ade0faefe07f1cf8d5f6d862d65d0"; # HEAD for the rvv-next branch
    sha256 = "sha256-cc8Gn/RPBmgeXrLFNX+Y6r2M6eDoXSlIMZIM3sBgvok=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    curl # required by configure, unused but no way to hack

    # required for generating document
    perl
    python3
    texinfo
    bison
    flex

    # stamps/build-linux-headers
    gmp
    mpfr
    libmpc

    flock # required for installing file
    expat # glibc
  ];

  # make -j$(nproc)
  enableParallelBuilding = true;

  configureFlags = [
    "--with-arch=rv32gcv" "--with-abi=ilp32d"
  ];

  # RUN: make linux
  buildFlags =
    let
      # We have already clone all the submodule. This is a tricky hack that set $(XXX_SRC_GIT) to empty string to
      # prevent makefile from automatically initializing and updating the git submodules, which would violate purity.
      dontUpdateSrcs = map (name: name + "_SRC_GIT=");
    in
    [
      # build target
      "linux"

      # Install to nix out dir
      "INSTALL_DIR=${placeholder "out"}"
    ] ++
    (dontUpdateSrcs [ "BINUTILS" "GCC" "GDB" "GLIBC" "NEWLIB" "MUSL" "QEMU" "SPIKE" "LLVM" "DEJAGNU" ]);

  # -Wno-format-security
  hardeningDisable = [ "format" ];

  # patchelf doesn't recognize RISC-V
  dontPatchELF = true;
}
