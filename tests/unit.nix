{
  lib ? (import ../.).inputs.nixpkgs.lib,
}:
let
  modules = import ../repo-nix/lib/modular.nix {
    inherit lib;
    moduleDir = ./unit;
    extraArgs = {
      useEf = (import ../src/impl.nix { inherit lib; }).use;
    };
  };

  toTestTree = lib.attrsets.mapAttrs (
    name: module:
    (toTestTree module.children or { })
    // (lib.attrsets.mapAttrs' (caseDescription: lib.nameValuePair "test: ${caseDescription}") (
      module.content or { }
    ))
  );
in
toTestTree modules.moduleTree
