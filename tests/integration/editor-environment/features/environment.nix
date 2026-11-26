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

  computation = { requisites, rawExtensions, ... }: {
    extensions."shell"."profile" = {
      priority = 1000;
      content = ''
        source <(${extraArgs.pkgs.systemd}/lib/systemd/user-environment-generators/30-systemd-environment-d-generator)
      '';
    };

    effects."nixos" = { config, pkgs, ... }: {
      users.users."root".maid = {
        file.xdg_config."environment.d/60-custom-session-vars.conf".text =
          lib.pipe rawExtensions."variables"
            [
              (lib.attrsets.concatMapAttrs (_: ext: ext.anySession))
              (lib.strings.concatMapAttrsStringSep "\n" (k: v: "${k}=${v}"))
            ];
      };
    };
  };
}
