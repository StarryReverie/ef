{
  lib ? (import ../.).inputs.nixpkgs.lib,
}:
import ./modular.nix {
  inherit lib;
  moduleDir = ./impl;
}
