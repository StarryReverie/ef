{ lib, use }:
let
  # Option tree for a feature's computation result
  computationOption = {
    value = lib.mkOption {
      type = lib.types.raw;
      description = ''
        Pure part of a feature's computation result.

        The pure part of result can be consumed by other dependent features actively, via other
        features' `requires` declaration and `requisites` parameter.
      '';
      default = { };
      example = lib.literalExperssion ''
        {
          envFile = "~/.config/environment.d/60-custom-session-vars.conf";
        };
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.raw);
      description = ''
        Pure part of a feature's computation result passed to other features.

        Pure extension data can be consumed by other dependent features passively, via the current
        feature's `extends` declaration and other features' `extensions` parameter. Those features
        only declare their extension point schema and will receive all extension data from outside
        when doing their own computation.

        The structure of this option is `.<otherFeatureName>.<otherExtensionName> = ...`.
      '';
      example = lib.literalExperssion ''
        {
          "users/starryreverie/core/shell".profile = {
            content = "...";
            priority = 1000;
          };
        };
      '';
    };

    effects = lib.mkOption {
      type = lib.types.attrsOf lib.types.raw;
      description = ''
        Effectful part of a feature's computation result.

        The effects are represented as Nix modules. Nix modules such as `nixpkgs/nixos` or
        `home-manager` are the ways to actually configure a NixOS system. Feature generates the
        Nix modules as its effects.

        Effects may have distinct kinds, you can separate different kinds of effects using different
        names. The structure of this option is `.<effectKind> = ...`.
      '';
      example = lib.literalExperssion ''
        {
          nixos = { config, ... }: {
            # Use `nix-maid` inside a NixOS module here
            users.users.starryreverie.maid = {
              file.xdg_config."environment.d/60-custom-session-vars.conf".text = "...";
              file.xdg_config."environment.d/60-custom-graphical-session-vars.conf".text = "...";
            };
          };
        }
      '';
    };
  };
in
{
  inherit
    computationOption
    ;
}
