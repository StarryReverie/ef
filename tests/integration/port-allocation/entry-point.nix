{
  inputs,
  pkgs,
  efApi,
}:
let
  features = {
    "configuration" = import ./features/configuration.nix;
  };

  runResult = efApi.runFeatures {
    enabledFeatures = [
      "configuration"
    ];
    extraArgs = { inherit inputs pkgs; };
  } features;
in
{
  module = (efApi.effectsToNixModules runResult).nixos;
  testScript = builtins.readFile ./test-script.py;
}
