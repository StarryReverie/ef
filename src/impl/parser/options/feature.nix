{ lib, use, ... }:
let
  # Option tree for a feature definition
  featureOption = {
    name = featureNameOption;

    requires = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options.name = featureNameOption;

          options.isExplicit = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether this dependent feature should be imported explicitly.

              If so, this dependent feature should be declared in the top-level entry point if it's
              required by the current feature, otherwise an error is raised. If the feature is
              implicitly required, it will be included in the feature graph automatically.
            '';
          };
        }
      );
      description = ''
        List of features that are required by the current feature.

        Those features' computation results are supplied to the current feature's computation. The
        current feature depends on those features. Usually you will use `efLib.useExplicitly` or
        `efLib.useImplicitly` to create such declaration.
      '';
      default = [ ];
      example = lib.literalExpression ''
        [
          (efLib.useImplicitly "system/core/environment")
          (efLib.useExplicitly "users/starryreverie/core/constants")
        ]
      '';
    };

    extends = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = ''
        List of features that are extended by the current feature.

        Those extended features passively accept the data from the current feature. The current
        feature is dependent by those extended features.
      '';
      default = [ ];
      example = lib.literalExpression ''
        [
          "users/starryreverie/core/shell"
        ]
      '';
    };

    schemas = {
      value = lib.mkOption {
        type = lib.types.raw;
        description = ''
          Option declaration or tree of the current feature's computation result.

          The current feature's computation result should satisfy the declaration of the option
          declaration or tree. You can use a single `lib.mkOption` or write the value part of the
          `options = { ... }` key-value pair.
        '';
        default = { };
        example = lib.literalExpression ''
          {
            envFile = lib.mkOption {
              type = lib.types.str;
              description = "Path to the generated environment file";
            };
          }
        '';
      };

      extensions = lib.mkOption {
        type = lib.types.attrsOf lib.types.raw;
        description = ''
          Option declaration or tree of the current feature's named extension points.

          Each extension point's option tree is associated with the corresponding name. The current
          feature's extension points should satisfy the declaration of the option declaration or
          tree. You can use a single `lib.mkOption` or write the value part of the
          `options = { ... }` key-value pair.
        '';
        example = lib.literalExpression ''
          {
            variables = {
              anySession = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                description = "All session environment variables to be set per-user";
                default = { };
                example = {
                  EDITOR = "hx";
                };
              };

              graphicalSession = lib.mkOption {
                type = lib.types.attrsOf lib.types.str;
                description = "All graphical session environment variables to be set per-user";
                default = { };
                example = {
                  LANG = "zh_CN.UTF-8";
                };
              };
            };
          }
        '';
      };
    };

    computation = lib.mkOption {
      type = lib.types.raw;
      description = ''
        Computation of a feature.

        A feature's computation is a function that receives the feature's dependencies's computation
        results, including extension values. This computation then produces the current feature's
        own computation result, extension values to other features, and underlying effects, which
        are represented by the ordinary nix module system.
      '';
      example = lib.literalExpression ''
        # `requisites.<otherFeatureName>.<...>`
        #   - e.g. `requisites."users/starryreverie/core/constants".hostName`
        # `extensions.<selfExtensionName>.<otherFeatureName>.<...>`
        #   - e.g. `extensions.variables."users/starryreverie/applications/helix".anySession.EDITOR`
        { requisites, extensions, ... }: {
          value = {
            envFile = "~/.config/environment.d/60-custom-session-vars.conf";
          };

          # `extensions.<otherFeatureName>.<otherExtensionName>`
          extensions."users/starryreverie/core/shell".profile = {
            content = "...";
            priority = 1000;
          };

          # `effects.<moduleTypeName>.<realNixModuleSystem>`
          effects.nixos = { config, ... }: {
            users.users.starryreverie.maid = {
              file.xdg_config."environment.d/60-custom-session-vars.conf".text = "...";
            };
          }
        }
      '';
    };
  };

  featureNameOption = lib.mkOption {
    type = lib.types.str;
    description = "Unique identifier of a feature";
    example = "system/core/environment";
  };
in
{
  inherit
    featureOption
    ;
}
