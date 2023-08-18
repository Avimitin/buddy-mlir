{ lib, stdenv, fetchFromGitHub, dtc }:

stdenv.mkDerivation rec {
  pname = "spike";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "riscv";
    repo = "riscv-isa-sim";
    rev = "v${version}";
    sha256 = "sha256-4D2Fezej0ioOOupw3kgMT5VLs+/jXQjwvek6v0AVMzI=";
  };

  nativeBuildInputs = [ dtc ];
  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs scripts/*.sh
    patchShebangs tests/ebreak.py
  '';

  doCheck = true;
}
