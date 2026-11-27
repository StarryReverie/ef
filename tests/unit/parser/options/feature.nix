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

  parseFeature = parseWithOption {
    options = featureOption;
    location = "<test-feature>";
  };
in
{
  "a minimal feature definition uses default values" = {
    expr =
      let
        parsed = parseFeature {
          inherit computation;
        };
      in
      {
        inherit (parsed)
          requires
          extends
          schemas
          ;
        computationIsFunction = builtins.isFunction parsed.computation;
      };
    expected = {
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
          requires = [
            {
              name = "dep-implicit";
              isExplicit = false;
            }
            {
              name = "dep-explicit";
              isExplicit = true;
            }
          ];
          extends = [ "base-feature" ];
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
        inherit (parsed) requires extends;
        valueKeys = lib.attrsets.attrNames parsed.schemas.value;
        extensionKeys = lib.attrsets.attrNames parsed.schemas.extensions;
        extensionPointKeys = lib.attrsets.attrNames parsed.schemas.extensions.variables;
        valueConfig =
          parseWithOption
            {
              options = parsed.schemas.value;
              location = "<test-value>";
            }
            {
              envFile = "/tmp/env";
            };
        extensionConfig =
          parseWithOption
            {
              options = parsed.schemas.extensions.variables;
              location = "<test-extension>";
            }
            {
              anySession.EDITOR = "hx";
            };
      };
    expected = {
      requires = [
        {
          name = "dep-implicit";
          isExplicit = false;
        }
        {
          name = "dep-explicit";
          isExplicit = true;
        }
      ];
      extends = [ "base-feature" ];
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
      requires = "not-a-list";
      inherit computation;
    };
    expectedError = {
      type = "ThrownError";
      message = "<test-feature>";
    };
  };

  "a non-list `extends` value is rejected" = {
    expr = parseFeature {
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
    };
    expectedError = {
      type = "ThrownError";
      message = "no value defined";
    };
  };
}
