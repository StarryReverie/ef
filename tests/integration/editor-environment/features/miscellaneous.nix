{
  lib,
  efLib,
  extraArgs,
  ...
}:
{
  name = "miscellaneous";

  computation = { requisites, rawExtensions, ... }: {
    effects."nixos" = { config, pkgs, ... }: {
      imports = [
        extraArgs.inputs.nix-maid.nixosModules.default
      ];

      services.getty.autologinUser = "root";

      virtualisation.vmVariant = {
        virtualisation.diskImage = null;
      };

      system.stateVersion = "26.11";
    };
  };
}
