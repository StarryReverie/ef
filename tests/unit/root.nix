{ lib, extraArgs, ... }:
let
  inherit (extraArgs.useEf "root")
    runFeatures
    ;
in
let
  features = {
    "base" =
      { lib, ... }:
      {
        name = "base";
        schemas.value = {
          n = lib.mkOption { type = lib.types.int; };
        };
        computation = { ... }: {
          value = {
            n = 1;
          };
          extensions = { };
        };
      };

    "app" =
      { lib, efLib, ... }:
      {
        name = "app";
        requires = [ (efLib.useImplicitly "base") ];
        schemas.value = {
          n = lib.mkOption { type = lib.types.int; };
        };
        computation = { requisites, ... }: {
          value = {
            n = requisites."base".n + 1;
          };
          extensions = { };
        };
      };

    "extra" =
      { lib, extraArgs, ... }:
      {
        name = "extra";
        schemas.value = {
          greeting = lib.mkOption { type = lib.types.str; };
        };
        computation = { ... }: {
          value = { inherit (extraArgs) greeting; };
          extensions = { };
        };
      };

    "unused" =
      { lib, ... }:
      {
        name = "unused";
        schemas = {
          value = { };
          extensions = { };
        };
        computation = { ... }: builtins.throw "unused feature should not be computed";
      };

    "target" =
      { lib, ... }:
      {
        name = "target";
        schemas = {
          value = {
            got = lib.mkOption { type = lib.types.str; };
          };
          extensions.profile = {
            content = lib.mkOption { type = lib.types.str; };
          };
        };
        computation = { extensions, ... }: {
          value = {
            got = extensions.profile."extender".content;
          };
          extensions = { };
        };
      };

    "extender" =
      { lib, ... }:
      {
        name = "extender";
        extends = [ "target" ];
        schemas = {
          value = { };
          extensions = { };
        };
        computation = { ... }: {
          value = { };
          extensions."target".profile = {
            content = "from-extender";
          };
        };
      };
  };
in
{
  "explicit and implicit `requires` are computed with extra arguments" = {
    expr =
      let
        result = runFeatures {
          explicitlyEnabledFeatureNames = [
            "app"
            "extra"
          ];
          extraArgs = {
            greeting = "hello";
          };
        } features;
      in
      {
        names = builtins.attrNames result;
        base = result."base".value;
        app = result."app".value;
        extra = result."extra".value;
        hasUnused = result ? "unused";
      };
    expected = {
      names = [
        "app"
        "base"
        "extra"
      ];
      base = {
        n = 1;
      };
      app = {
        n = 2;
      };
      extra = {
        greeting = "hello";
      };
      hasUnused = false;
    };
  };

  "incoming extensions reach enabled targets" = {
    expr =
      let
        result = runFeatures {
          explicitlyEnabledFeatureNames = [
            "target"
            "extender"
          ];
          extraArgs = { };
        } features;
      in
      {
        target = result."target".value;
        extender = result."extender".extensions;
      };
    expected = {
      target = {
        got = "from-extender";
      };
      extender = {
        "target".profile = {
          content = "from-extender";
        };
      };
    };
  };

  "extensions to disabled targets are validated but not delivered" = {
    expr =
      let
        result = runFeatures {
          explicitlyEnabledFeatureNames = [ "extender" ];
          extraArgs = { };
        } features;
      in
      {
        names = builtins.attrNames result;
        extender = result."extender".extensions;
        hasTarget = result ? "target";
      };
    expected = {
      names = [ "extender" ];
      extender = {
        "target".profile = {
          content = "from-extender";
        };
      };
      hasTarget = false;
    };
  };
}
