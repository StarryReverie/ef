{
  lib,
  efLib,
  extraArgs,
  ...
}:
{
  name = "environment";

  extends = [
    "shell"
  ];

  schemas.extensions."variables" = {
    anySession = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
    };
  };

  computation = { requisites, extensions, ... }: {
    extensions."shell"."profile" = ''
      source <(${extraArgs.pkgs.systemd}/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
    '';

    effects."nixos" = { config, pkgs, ... }: {
      users.users."root".maid = {
        file.xdg_config."environment.d/60-custom-session-vars.conf".text =
          lib.strings.concatMapAttrsStringSep "\n" (k: v: "${k}=${v}")
            extensions."variables".anySession;
      };
    };
  };
}
