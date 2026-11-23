{ lib, extraArgs, ... }:
let
  inherit (extraArgs.useEf "root")
    effectsToNixModules
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

  effectFeatures = {
    "a" =
      { lib, ... }:
      {
        name = "a";
        schemas = {
          value = { };
          extensions = { };
        };
        computation = { ... }: {
          value = { };
          extensions = { };
          effects.nixos = { ... }: {
            config.result = [ "a" ];
          };
          effects.other = { ... }: {
            config.result = [ "a-other" ];
          };
        };
      };

    "b" =
      { lib, ... }:
      {
        name = "b";
        schemas = {
          value = { };
          extensions = { };
        };
        computation = { ... }: {
          value = { };
          extensions = { };
          effects.nixos = {
            config.result = [ "b" ];
          };
          effects.other = {
            config.result = [ "b-other" ];
          };
        };
      };

    "user-file" =
      { lib, ... }:
      {
        name = "user-file";
        schemas = {
          value = { };
          extensions = { };
        };
        computation = { ... }: {
          value = { };
          extensions = { };
          effects.nixos = {
            _file = "<user-provided>";
            config.result = [ "user" ];
          };
        };
      };

    "disabled" =
      { lib, ... }:
      {
        name = "disabled";
        schemas = {
          value = { };
          extensions = { };
        };
        computation = { ... }: {
          value = { };
          extensions = { };
          effects.nixos = {
            config.result = [ "disabled" ];
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
          enabledFeatures = [
            "app"
            "extra"
          ];
          extraArgs = {
            greeting = "hello";
          };
        } features;
      in
      {
        names = lib.attrsets.attrNames result;
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
          enabledFeatures = [
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
          enabledFeatures = [ "extender" ];
          extraArgs = { };
        } features;
      in
      {
        names = lib.attrsets.attrNames result;
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

  "effect modules are merged by kind" = {
    expr =
      let
        result = runFeatures {
          enabledFeatures = [
            "a"
            "b"
            "user-file"
          ];
          extraArgs = { };
        } effectFeatures;
        merged = effectsToNixModules result;
        optionsModule = {
          options.result = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
          };
        };
        sort = lib.lists.sort (a: b: a < b);
        nixosImports = merged."nixos".imports;
      in
      {
        effectKinds = lib.attrsets.attrNames merged;
        nixosImportCount = lib.lists.length nixosImports;
        otherImportCount = lib.lists.length merged."other".imports;
        nixosValues =
          sort
            (lib.evalModules {
              modules = [
                optionsModule
                merged."nixos"
              ];
            }).config.result;
        otherValues =
          sort
            (lib.evalModules {
              modules = [
                optionsModule
                merged."other"
              ];
            }).config.result;
        empty = effectsToNixModules { };
      };
    expected = {
      effectKinds = [
        "nixos"
        "other"
      ];
      nixosImportCount = 3;
      otherImportCount = 2;
      nixosValues = [
        "a"
        "b"
        "user"
      ];
      otherValues = [
        "a-other"
        "b-other"
      ];
      empty = { };
    };
  };
}
