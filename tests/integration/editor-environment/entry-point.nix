{
  inputs,
  pkgs,
  efApi,
}:
let
  features = {
    "environment" = import ./features/environment.nix;
    "helix" = import ./features/helix.nix;
    "miscellaneous" = import ./features/miscellaneous.nix;
    "shell" = import ./features/shell.nix;
    "zsh" = import ./features/zsh.nix;
  };

  runResult = efApi.runFeatures {
    enabledFeatures = [
      "environment"
      "helix"
      "miscellaneous"
      "zsh"
    ];
    extraArgs = { inherit inputs pkgs; };
  } features;
in
{
  module = (efApi.effectsToNixModules runResult).nixos;
  testScript = builtins.readFile ./test-script.py;
}
