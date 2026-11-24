{ config, inputs, ... }:
{
  imports = [
    ./lib.nix
  ];

  perSystem =
    { system, ... }:
    {
      _module.args.pkgs = inputs.nixpkgs.legacyPackages.${system};
    };

  flake.inputs = inputs;
}
