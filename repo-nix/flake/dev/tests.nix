{ config, inputs, ... }:
{
  flake.libTests = import ../../../tests/unit.nix {
    lib = inputs.nixpkgs.lib;
  };
}
