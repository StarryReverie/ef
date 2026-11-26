{
  lib,
  efLib,
  extraArgs,
  ...
}:
{
  name = "helix";

  extends = [
    "environment"
    "shell"
  ];

  computation = { requisites, rawExtensions, ... }: {
    extensions."environment"."variables" = {
      anySession = {
        "EDITOR" = "hx";
        "VISUAL" = "hx";
      };
    };

    extensions."shell"."aliases" = {
      "helix" = "hx";
      "vi" = "hx";
      "vim" = "hx";
    };

    effects."nixos" = { config, pkgs, ... }: {
      users.users."root".maid = {
        packages = [ pkgs.helix ];

        file.xdg_config."helix/config.toml".text = ''
          [editor.statusline.mode]
          insert = "INSERT"
          normal = "NORMAL"
          select = "SELECT"
        '';
      };
    };
  };
}
