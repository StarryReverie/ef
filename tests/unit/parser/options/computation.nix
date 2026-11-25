{ lib, extraArgs, ... }:
let
  inherit (extraArgs.useEf "parser.options")
    parseWithOption
    ;
  inherit (extraArgs.useEf "parser.options.computation")
    computationOption
    ;
in
let
  parseComputation = parseWithOption {
    options = computationOption;
    location = "<test-computation>";
  };
in
{
  "explicit fields are preserved and defaults are applied" = {
    expr = {
      defaults = parseComputation { };
      explicit = parseComputation {
        value = {
          envFile = "/tmp/env";
        };
        extensions."other/feature".profile = {
          content = "...";
          priority = 1000;
        };
        effects.nixos = "module";
      };
    };
    expected = {
      defaults = {
        value = { };
        extensions = { };
        effects = { };
      };
      explicit = {
        value = {
          envFile = "/tmp/env";
        };
        extensions = {
          "other/feature".profile = {
            content = "...";
            priority = 1000;
          };
        };
        effects = {
          nixos = "module";
        };
      };
    };
  };

  "an extension value that is not an attrset is rejected" = {
    expr = parseComputation {
      extensions."other/feature" = "not-an-attrset";
    };
    expectedError = {
      type = "ThrownError";
      message = "<test-computation>";
    };
  };

  "a non-attrset `effects` value is rejected" = {
    expr = parseComputation {
      effects = "not-an-attrset";
    };
    expectedError = {
      type = "ThrownError";
      message = "not of type";
    };
  };
}
