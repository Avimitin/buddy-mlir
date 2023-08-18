{ rv32-clangxx, riscv-cxx-runtime, buddy-mlir, stdenv, llvmForDev, glibc_multi, fetchurl }:
stdenv.mkDerivation {
  pname = "bert-mlir";
  version = "unstable-2023-08-17";

  srcs = [
    (fetchurl {
      url = "https://raw.githubusercontent.com/xlinsist/buddy-mlir/bert/examples/DLModel/bert-with-weights.mlir";
      sha256 = "sha256-TksI5EX5S4bhPNmgRH5t/M1Y72VQrhx7ASvEFdW4NkU=";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/xlinsist/buddy-mlir/bert/frontend/Interfaces/buddy/Core/Container.h";
      sha256 = "sha256-QWl/UUcoQP6GZ0bDnp4QSrg7gZMqUCFHDsUtGWGzbXY=";
    })
    (fetchurl {
      url = "https://raw.githubusercontent.com/xlinsist/buddy-mlir/bert/examples/DLModel/sentiment-classification.cpp";
      sha256 = "sha256-JGtYETV2GqB8/Ec+u0HQx1RDnLtE9TPzWGppjUcU3gw=";
    })
  ];
  sourceRoot = "bert";
  unpackPhase = ''
    runHook preUnpack

    mkdir -p bert
    for _src in $srcs; do
      cp $_src ./bert/$(stripHash $_src)
    done

    runHook postUnpack
  '';
  patchPhase = ''
    runHook prePatch

    substituteInPlace ./sentiment-classification.cpp \
      --replace '#include "../../frontend/Interfaces/buddy/Core/Container.h"' '#include "./Container.h"'

    runHook postPatch
  '';

  nativeBuildInputs = [ buddy-mlir riscv-cxx-runtime rv32-clangxx llvmForDev.bintools ];

  buildInputs = [ glibc_multi ]; #libcxx libcxxabi libunwind ];

  buddyOptArg = [
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
    "--convert-math-to-llvm"
    "--llvm-request-c-wrappers"
    "--convert-func-to-llvm"
    "--reconcile-unrealized-casts"
  ];
  llcArg = [ "-O3" "-mtriple=riscv32" "-target-abi=ilp32" "-mattr=+m,+d,+v" "-filetype=obj" "-riscv-v-vector-bits-min=128" ];

  dontDisableStatic = true;
  dontAddStaticConfigureFlags = true;
  NIX_DONT_SET_RPATH = true;

  buildPhase = ''
    runHook preBuild

    buddy-opt ./bert-with-weights.mlir $buddyOptArg \
      | buddy-translate --buddy-to-llvmir \
      | buddy-llc $llcArg -o bert.o
    readelf -h bert.o
    clang++-rv32 -c sentiment-classification.cpp \
      -static -mabi=ilp32d \
      -o sentiment-classification.o
    readelf -h sentiment-classification.o
    clang++-rv32 bert.o sentiment-classification.o \
      -mabi=ilp32f -mno-relax -static -mcmodel=medany -fvisibility=hidden -fno-PIC \
      -o sentiment-classification

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp ./sentiment-classification $out/bin

    runHook postInstall
  '';
}
