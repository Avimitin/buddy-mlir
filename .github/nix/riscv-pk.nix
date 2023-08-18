{ stdenv, riscv-gnu-toolchain, fetchFromGitHub, autoreconfHook }:
stdenv.mkDerivation rec {
  pname = "riscv-pk";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "riscv";
    repo = "riscv-pk";
    rev = "v${version}";
    sha256 = "1cc0rz4q3a1zw8756b8yysw8lb5g4xbjajh5lvqbjix41hbdx6xz";
  };

  nativeBuildInputs = [ autoreconfHook riscv-gnu-toolchain ];

  preConfigure = ''
    mkdir build
    cd build

    export CC=${riscv-gnu-toolchain}/bin/riscv64-unknown-linux-gnu-gcc
    export AR=${riscv-gnu-toolchain}/bin/riscv64-unknown-linux-gnu-ar
    export RANLIB=${riscv-gnu-toolchain}/bin/riscv64-unknown-linux-gnu-ranlib
    export READELF=${riscv-gnu-toolchain}/bin/riscv64-unknown-linux-gnu-readelf
    export OBJCOPY=${riscv-gnu-toolchain}/bin/riscv64-unknown-linux-gnu-objcopy
  '';

  configureScript = "../configure";

  configureFlags = [ "--host=riscv64-unknown-linux-gnu" ];

  #hardeningDisable = [ "all" ];

  postInstall = ''
    mv $out/* $out/.cleanup
    mv $out/.cleanup/* $out
    rmdir $out/.cleanup
  '';

  dontPatchELF = true;
}
