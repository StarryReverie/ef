{ config, inputs, ... }:
{
  flake.lib = config.flake.mkLib {
    lib = inputs.nixpkgs.lib;
  };

  flake.mkLib = import ../../src/default.nix;
}
