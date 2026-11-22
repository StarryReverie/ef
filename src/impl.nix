{
  lib ? (import ../.).inputs.nixpkgs.lib,
}:
import ../repo-nix/lib/modular.nix {
  inherit lib;
  moduleDir = ./impl;
}
