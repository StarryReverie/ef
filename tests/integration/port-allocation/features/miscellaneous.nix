{
  lib,
  efLib,
  extraArgs,
  ...
}:
{

  computation = { requisites, extensions, ... }: {
    effects."nixos" = { config, pkgs, ... }: {
      environment.loginShellInit = ''
        echo 'Please run `open-ef` and `open-hello` to open two web pages'
      '';

      services.getty.autologinUser = "root";

      virtualisation.vmVariant = {
        virtualisation.diskImage = null;
      };

      system.stateVersion = "26.11";
    };
  };
}
