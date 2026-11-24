{ pkgs, efApi }:
let
  features = {
    "configuration" = import ./features/configuration.nix;
  };

  runResult = efApi.runFeatures {
    enabledFeatures = [
      "configuration"
    ];
    extraArgs = { inherit pkgs; };
  } features;
in
{
  module = (efApi.effectsToNixModules runResult).nixos;
}
