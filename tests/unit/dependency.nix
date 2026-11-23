{ lib, extraArgs, ... }:
let
  inherit (extraArgs.useEf "dependency")
    makeDependencyGraph
    ;
in
let
  useImplicitly = name: {
    inherit name;
    isExplicit = false;
  };

  useExplicitly = name: {
    inherit name;
    isExplicit = true;
  };

  makeFeature =
    {
      name,
      requires ? [ ],
      extends ? [ ],
    }:
    {
      inherit name requires extends;
      computation = { ... }: { };
    };

  normalizeGraph = lib.attrsets.mapAttrs (
    _: node: {
      required = lib.lists.sort (a: b: a < b) node.required;
      extendedBy = lib.lists.sort (a: b: a < b) node.extendedBy;
    }
  );

  toGraph =
    allFeatures: explicitlyEnabledFeatureNames:
    normalizeGraph (makeDependencyGraph allFeatures explicitlyEnabledFeatureNames);

  throws = expression: !(builtins.tryEval (builtins.deepSeq expression true)).success;
in
{
  "dependency graphs contain required features and their closure" = {
    expr = {
      empty = toGraph { } [ ];
      single = toGraph {
        "a" = makeFeature { name = "a"; };
      } [ "a" ];
      independent =
        toGraph
          {
            "a" = makeFeature { name = "a"; };
            "b" = makeFeature { name = "b"; };
          }
          [
            "a"
            "b"
          ];
      outsideClosure = toGraph {
        "a" = makeFeature { name = "a"; };
      } [ ];
      isAttributeSet = builtins.isAttrs (
        makeDependencyGraph {
          "a" = makeFeature { name = "a"; };
        } [ "a" ]
      );
      implicitClosure = toGraph {
        "a" = makeFeature { name = "a"; };
        "b" = makeFeature {
          name = "b";
          requires = [
            (useImplicitly "a")
            (useImplicitly "a")
          ];
        };
        "c" = makeFeature {
          name = "c";
          requires = [ (useImplicitly "b") ];
        };
      } [ "c" ];
      explicitEnabled =
        toGraph
          {
            "x" = makeFeature { name = "x"; };
            "y" = makeFeature {
              name = "y";
              requires = [ (useExplicitly "x") ];
            };
          }
          [
            "x"
            "y"
          ];
    };
    expected = {
      empty = { };
      single = {
        "a" = {
          required = [ ];
          extendedBy = [ ];
        };
      };
      independent = {
        "a" = {
          required = [ ];
          extendedBy = [ ];
        };
        "b" = {
          required = [ ];
          extendedBy = [ ];
        };
      };
      outsideClosure = { };
      isAttributeSet = true;
      implicitClosure = {
        "a" = {
          required = [ ];
          extendedBy = [ ];
        };
        "b" = {
          required = [ "a" ];
          extendedBy = [ ];
        };
        "c" = {
          required = [ "b" ];
          extendedBy = [ ];
        };
      };
      explicitEnabled = {
        "x" = {
          required = [ ];
          extendedBy = [ ];
        };
        "y" = {
          required = [ "x" ];
          extendedBy = [ ];
        };
      };
    };
  };

  "dependency graphs contain extensions of enabled features" = {
    expr = {
      extensions =
        toGraph
          {
            "a" = makeFeature { name = "a"; };
            "b" = makeFeature {
              name = "b";
              extends = [
                "a"
                "a"
              ];
            };
            "c" = makeFeature {
              name = "c";
              extends = [ "a" ];
            };
          }
          [
            "a"
            "b"
            "c"
          ];
      onlyExtender = toGraph {
        "a" = makeFeature { name = "a"; };
        "b" = makeFeature {
          name = "b";
          extends = [ "a" ];
        };
      } [ "b" ];
      disabledExtender = toGraph {
        "a" = makeFeature { name = "a"; };
        "c" = makeFeature {
          name = "c";
          extends = [ "a" ];
        };
      } [ "a" ];
      mixed =
        toGraph
          {
            "a" = makeFeature { name = "a"; };
            "b" = makeFeature {
              name = "b";
              requires = [ (useImplicitly "c") ];
              extends = [ "a" ];
            };
            "c" = makeFeature {
              name = "c";
              requires = [ (useImplicitly "d") ];
            };
            "d" = makeFeature { name = "d"; };
          }
          [
            "a"
            "b"
            "c"
            "d"
          ];
    };
    expected = {
      extensions = {
        "a" = {
          required = [ ];
          extendedBy = [
            "b"
            "c"
          ];
        };
        "b" = {
          required = [ ];
          extendedBy = [ ];
        };
        "c" = {
          required = [ ];
          extendedBy = [ ];
        };
      };
      onlyExtender = {
        "b" = {
          required = [ ];
          extendedBy = [ ];
        };
      };
      disabledExtender = {
        "a" = {
          required = [ ];
          extendedBy = [ ];
        };
      };
      mixed = {
        "a" = {
          required = [ ];
          extendedBy = [ "b" ];
        };
        "b" = {
          required = [ "c" ];
          extendedBy = [ ];
        };
        "c" = {
          required = [ "d" ];
          extendedBy = [ ];
        };
        "d" = {
          required = [ ];
          extendedBy = [ ];
        };
      };
    };
  };

  "invalid declarations are rejected" = {
    expr = {
      unknownExplicit = throws (
        makeDependencyGraph
          {
            "a" = makeFeature { name = "a"; };
          }
          [
            "a"
            "ghost"
          ]
      );
      missingRequirement = throws (
        makeDependencyGraph {
          "a" = makeFeature {
            name = "a";
            requires = [ (useImplicitly "ghost") ];
          };
        } [ "a" ]
      );
      missingExtension = throws (
        makeDependencyGraph {
          "a" = makeFeature {
            name = "a";
            extends = [ "ghost" ];
          };
        } [ "a" ]
      );
      selfRequirement = throws (
        makeDependencyGraph {
          "a" = makeFeature {
            name = "a";
            requires = [ (useImplicitly "a") ];
          };
        } [ "a" ]
      );
      selfExtension = throws (
        makeDependencyGraph {
          "a" = makeFeature {
            name = "a";
            extends = [ "a" ];
          };
        } [ "a" ]
      );
      unenabledExplicitRequirement = throws (
        makeDependencyGraph {
          "a" = makeFeature { name = "a"; };
          "b" = makeFeature {
            name = "b";
            requires = [ (useExplicitly "a") ];
          };
        } [ "b" ]
      );
      inactiveInvalidRequirement = throws (
        makeDependencyGraph {
          "a" = makeFeature { name = "a"; };
          "z" = makeFeature {
            name = "z";
            requires = [ (useImplicitly "ghost") ];
          };
        } [ "a" ]
      );
    };
    expected = {
      unknownExplicit = true;
      missingRequirement = true;
      missingExtension = true;
      selfRequirement = true;
      selfExtension = true;
      unenabledExplicitRequirement = true;
      inactiveInvalidRequirement = true;
    };
  };

  "a declaration error reports the offending feature and requirement" = {
    expr = makeDependencyGraph {
      "a" = makeFeature { name = "a"; };
      "z" = makeFeature {
        name = "z";
        requires = [ (useImplicitly "ghost") ];
      };
    } [ "a" ];
    expectedError = {
      type = "ThrownError";
      message = "feature 'z' depends on non-existent feature 'ghost'";
    };
  };

  "cyclic dependencies are rejected" = {
    expr = {
      requires = throws (
        makeDependencyGraph {
          "a" = makeFeature {
            name = "a";
            requires = [ (useImplicitly "b") ];
          };
          "b" = makeFeature {
            name = "b";
            requires = [ (useImplicitly "a") ];
          };
        } [ "a" ]
      );
      transitiveRequires = throws (
        makeDependencyGraph {
          "a" = makeFeature {
            name = "a";
            requires = [ (useImplicitly "b") ];
          };
          "b" = makeFeature {
            name = "b";
            requires = [ (useImplicitly "c") ];
          };
          "c" = makeFeature {
            name = "c";
            requires = [ (useImplicitly "a") ];
          };
        } [ "a" ]
      );
      prefixedRequires = throws (
        makeDependencyGraph {
          "a" = makeFeature {
            name = "a";
            requires = [ (useImplicitly "b") ];
          };
          "b" = makeFeature {
            name = "b";
            requires = [ (useImplicitly "c") ];
          };
          "c" = makeFeature {
            name = "c";
            requires = [ (useImplicitly "b") ];
          };
        } [ "a" ]
      );
      extensions = throws (
        makeDependencyGraph
          {
            "a" = makeFeature {
              name = "a";
              extends = [ "b" ];
            };
            "b" = makeFeature {
              name = "b";
              extends = [ "a" ];
            };
          }
          [
            "a"
            "b"
          ]
      );
      mixed = throws (
        makeDependencyGraph
          {
            "a" = makeFeature { name = "a"; };
            "b" = makeFeature {
              name = "b";
              requires = [ (useImplicitly "a") ];
              extends = [ "a" ];
            };
          }
          [
            "a"
            "b"
          ]
      );
      outsideClosure = throws (
        makeDependencyGraph {
          "a" = makeFeature { name = "a"; };
          "x" = makeFeature {
            name = "x";
            requires = [ (useImplicitly "y") ];
          };
          "y" = makeFeature {
            name = "y";
            requires = [ (useImplicitly "x") ];
          };
        } [ "a" ]
      );
    };
    expected = {
      requires = true;
      transitiveRequires = true;
      prefixedRequires = true;
      extensions = true;
      mixed = true;
      outsideClosure = false;
    };
  };

  "a cycle error reports a cyclic dependency path" = {
    expr = makeDependencyGraph {
      "a" = makeFeature {
        name = "a";
        requires = [ (useImplicitly "b") ];
      };
      "b" = makeFeature {
        name = "b";
        requires = [ (useImplicitly "a") ];
      };
    } [ "a" ];
    expectedError = {
      type = "ThrownError";
      message = "encountered cyclic dependency path";
    };
  };
}
