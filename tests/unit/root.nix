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
        schemas = {
          value = { };
          extensions = { };
        };
        computation = { ... }: builtins.throw "unused feature should not be computed";
      };

    "target" =
      { lib, ... }:
      {
        schemas = {
          value = {
            got = lib.mkOption { type = lib.types.str; };
          };
          extensions.profile = {
            content = lib.mkOption { type = lib.types.str; };
          };
        };
        computation = { rawExtensions, ... }: {
          value = {
            got = rawExtensions.profile."extender".content;
          };
          extensions = { };
        };
      };

    "extender" =
      { lib, ... }:
      {
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

  effectfulFeatures = {
    "a" =
      { lib, ... }:
      {
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
        result =
          (runFeatures {
            enabledFeatures = [
              "app"
              "extra"
            ];
            extraArgs = {
              greeting = "hello";
            };
          } features).result;
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
        result =
          (runFeatures {
            enabledFeatures = [
              "target"
              "extender"
            ];
            extraArgs = { };
          } features).result;
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
        result =
          (runFeatures {
            enabledFeatures = [ "extender" ];
            extraArgs = { };
          } features).result;
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
        } effectfulFeatures;
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
        empty = effectsToNixModules { result = { }; };
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

  "feature names are validated" = {
    expr =
      let
        runWithName =
          name:
          runFeatures
            {
              enabledFeatures = [ name ];
              extraArgs = { };
            }
            {
              ${name} = { ... }: {
                computation = { ... }: { };
              };
            };
        throws = name: !(builtins.tryEval (builtins.deepSeq (runWithName name) true)).success;
      in
      {
        validNames = lib.attrsets.attrNames (runWithName "valid_Name-123").result;
        slashRejected = throws "bad/name";
        spaceRejected = throws "bad name";
        dotRejected = throws "bad.name";
      };
    expected = {
      validNames = [ "valid_Name-123" ];
      slashRejected = true;
      spaceRejected = true;
      dotRejected = true;
    };
  };
}
