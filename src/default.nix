{
  lib ? (import ../.).inputs.nixpkgs.lib,
}:
let
  modules = import ./impl.nix { inherit lib; };
  inherit (modules) use;
in
{
  inherit (use "root")
    runFeatures
    effectsToNixModules
    ;
}
