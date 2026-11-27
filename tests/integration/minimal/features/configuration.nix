{ lib, efLib, ... }:
{

  computation = { requisites, extensions, ... }: {
    effects."nixos" = { config, pkgs, ... }: {
      environment.loginShellInit = ''
        echo 'Welcome to NixOS using ef'
      '';

      services.getty.autologinUser = "root";

      virtualisation.vmVariant = {
        virtualisation.diskImage = null;
      };

      system.stateVersion = "26.11";
    };
  };
}
