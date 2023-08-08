final: prev: {
  buddy-mlir = final.callPackage ./nix/buddy.nix { };
  libspike = final.callPackage ./nix/spike.nix { };
  bert-mlir = final.callPackage ./nix/bert-mlir.nix { };
}
