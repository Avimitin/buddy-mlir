{ stdenv, fetchFromGitHub, python3, ninja, pkg-config, glib, pixman, perl }:
stdenv.mkDerivation rec {
  pname = "qemu";
  version = "unstable-2023-08-18";

  src = fetchFromGitHub {
    owner = "sifive";
    repo = pname;
    rev = "856da0e94f";
    sha256 = "sha256-J2Lkjoch6Dox+1qI26q0gHN3lYIKork0xdk4cJ+XUAs=";
    fetchSubmodules = true;
  };

  buildInputs = [ glib ];
  nativeBuildInputs = [ python3 ninja pkg-config pixman ];

  preConfigure = ''
    mkdir build
    cd build
  '';

  # There is no /usr/bin/env inside chroot
  postPatch = ''
    find . -type f -name '*.py' -exec sed -i 's|^#!/usr/bin/env python$|#!${python3}/bin/python|' {} \;
    find . -type f -name '*.pl' -exec sed -i 's|^#!/usr/bin/env perl$|#!${perl}/bin/perl|' {} \;
  '';

  configureScript = "../configure";
  configureFlags = [ "--disable-werror" ];
  enableParallelBuilding = true;
}
