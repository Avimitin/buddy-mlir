{ stdenv, cmake, ninja, python3, fetchFromGitHub, lib }:
let
  pname = "buddy-mlir";
  version = "unstable-2023-08-02";

  # Copy only buddy component to avoid rebuild everytime repo got changed
  buddy-src = let
    nonBuddyMainSrc = {
      directory = [ "benchmark" "docs" "examples" "nix" "scripts" "tests" ];
      file = [ "LICENSE" "README.md" ];
    };
    isBuddyComponent = with builtins;
      path: type:
      let
        name = baseNameOf path;
        notHasSameName = patterns: !(any (f: f == name) patterns);
      in if type == "directory" then
        notHasSameName nonBuddyMainSrc.directory
      else if type == "regular" then
        notHasSameName nonBuddyMainSrc.file
      else
      # reject symlink and unknown file type
        false;
  in lib.cleanSourceWith {
    name = "${pname}-src-${version}";
    filter = isBuddyComponent;
    src = ../.;
  };

  llvm-src = fetchFromGitHub {
    owner = "llvm";
    repo = "llvm-project";
    rev = "8f966cedea594d9a91e585e88a80a42c04049e6c";
    sha256 = "sha256-g2cYk3/iyUvmIG0QCQpYmWj4L2H4znx9KbuA5TvIjrc=";
  };
in stdenv.mkDerivation rec {
  inherit pname version;
  srcs = [ buddy-src llvm-src ];
  sourceRoot = ".";
  unpackPhase = ''
    sources=($srcs)
    # [0] buddy-mlir
    cp -r ''${sources[0]} buddy-mlir
    # sources are copy from RO store
    chmod -R u+w -- buddy-mlir
    # [1] llvm: cmake is hard-coded to find llvm inside buddy-mlir
    cp -r ''${sources[1]} buddy-mlir/llvm
    chmod -R u+w -- buddy-mlir/llvm
  '';
  patchPhase = ''
    # These directories are excluded to avoid rebuild everytime
    substituteInPlace ./buddy-mlir/CMakeLists.txt \
      --replace 'add_subdirectory(examples)' "" \
      --replace 'add_subdirectory(tests)' ""
  '';
  # Bash variable is not resolved in cmakeFlags
  preConfigure = ''
    cmakeFlagsArray+=(
      -DLLVM_EXTERNAL_BUDDY_MLIR_SOURCE_DIR="$(realpath buddy-mlir)"
    )
  '';

  requiredSystemFeatures = [ "big-parallel" ];

  nativeBuildInputs = [ cmake ninja python3 ];

  # CMakeList is available in llvm main source inside the llvm repo
  cmakeDir = "../buddy-mlir/llvm/llvm";
  cmakeFlags = [
    "-DLLVM_ENABLE_PROJECTS=mlir;clang"
    "-DLLVM_TARGETS_TO_BUILD=host;RISCV"
    "-DLLVM_EXTERNAL_PROJECTS=${pname}"
    "-DLLVM_ENABLE_ASSERTIONS=ON"
    "-DLLVM_ENABLE_BINDINGS=OFF"
    "-DLLVM_ENABLE_OCAMLDOC=OFF"
    "-DLLVM_BUILD_EXAMPLES=OFF"
  ];

  checkTarget = "check-mlir check-clang check-buddy";
}
