{ lib, extraArgs, ... }:
let
  inherit (extraArgs.useEf "parser.options")
    parseWithOption
    ;
  inherit (extraArgs.useEf "parser.options.feature")
    featureOption
    ;
in
let
  computation = { ... }: { };

  parseFeature = parseWithOption featureOption;
in
{
  "a minimal feature definition uses default values" = {
    expr =
      let
        parsed = parseFeature {
          name = "test/minimal";
          inherit computation;
        };
      in
      {
        inherit (parsed)
          name
          requires
          extends
          schemas
          ;
        computationIsFunction = builtins.isFunction parsed.computation;
      };
    expected = {
      name = "test/minimal";
      requires = [ ];
      extends = [ ];
      schemas = {
        value = { };
        extensions = { };
      };
      computationIsFunction = true;
    };
  };

  "explicit `requires`, `extends`, and `schemas` are preserved" = {
    expr =
      let
        parsed = parseFeature {
          name = "test/full";
          requires = [
            {
              name = "dep/implicit";
              isExplicit = false;
            }
            {
              name = "dep/explicit";
              isExplicit = true;
            }
          ];
          extends = [ "base/feature" ];
          schemas = {
            value = {
              envFile = lib.mkOption { type = lib.types.str; };
            };
            extensions = {
              variables = {
                anySession = lib.mkOption {
                  type = lib.types.attrsOf lib.types.str;
                  default = { };
                };
              };
              naked = lib.mkOption { type = lib.types.int; };
            };
          };
          inherit computation;
        };
      in
      {
        inherit (parsed) name requires extends;
        valueKeys = builtins.attrNames parsed.schemas.value;
        extensionKeys = builtins.attrNames parsed.schemas.extensions;
        extensionPointKeys = builtins.attrNames parsed.schemas.extensions.variables;
        valueConfig = parseWithOption parsed.schemas.value {
          envFile = "/tmp/env";
        };
        extensionConfig = parseWithOption parsed.schemas.extensions.variables {
          anySession.EDITOR = "hx";
        };
      };
    expected = {
      name = "test/full";
      requires = [
        {
          name = "dep/implicit";
          isExplicit = false;
        }
        {
          name = "dep/explicit";
          isExplicit = true;
        }
      ];
      extends = [ "base/feature" ];
      valueKeys = [ "envFile" ];
      extensionKeys = [
        "naked"
        "variables"
      ];
      extensionPointKeys = [ "anySession" ];
      valueConfig = {
        envFile = "/tmp/env";
      };
      extensionConfig = {
        anySession.EDITOR = "hx";
      };
    };
  };

  "a non-list `requires` value is rejected" = {
    expr = parseFeature {
      name = "test/invalid-requires";
      requires = "not-a-list";
      inherit computation;
    };
    expectedError = {
      type = "ThrownError";
      message = "not of type";
    };
  };

  "a non-list `extends` value is rejected" = {
    expr = parseFeature {
      name = "test/invalid-extends";
      extends = "not-a-list";
      inherit computation;
    };
    expectedError = {
      type = "ThrownError";
      message = "not of type";
    };
  };

  "a feature without `computation` is rejected" = {
    expr = parseFeature {
      name = "test/missing-computation";
    };
    expectedError = {
      type = "ThrownError";
      message = "no value defined";
    };
  };
}
