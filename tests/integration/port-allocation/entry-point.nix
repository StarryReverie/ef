{
  inputs,
  pkgs,
  efApi,
}:
let
  features =
    {
      "miscellaneous" = import ./features/miscellaneous.nix;
      "registry" = import ./features/registry.nix;
    }
    // (import ./features/service-ef.nix { inherit pkgs; })
    // (import ./features/service-hello.nix { inherit pkgs; });

  runResult = efApi.runFeatures {
    enabledFeatures = [
      "miscellaneous"
      "registry"
      "ef-server"
      "hello-server"
    ];
    extraArgs = { inherit inputs pkgs; };
  } features;
in
{
  module = (efApi.effectsToNixModules runResult).nixos;
  testScript = builtins.readFile ./test-script.py;
}
