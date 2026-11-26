{
  lib,
  efLib,
  extraArgs,
  ...
}:
{
  name = "zsh";

  requires = [
    (efLib.useImplicitly "shell")
  ];

  computation = { requisites, rawExtensions, ... }: {
    effects."nixos" = { config, pkgs, ... }: {
      programs.zsh.enable = true;

      users.users."root".shell = config.programs.zsh.package;

      users.users."root".maid = {
        file.home.".zprofile".text = requisites."shell"."profile";

        file.home.".zshrc".text = lib.strings.concatMapAttrsStringSep "\n" (
          k: v: "alias -- ${k}=${lib.strings.escapeShellArg v}"
        ) requisites."shell"."aliases";
      };
    };
  };
}
