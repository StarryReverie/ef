{ lib, use }:
let
  inherit (use "parser.options.feature")
    featureOption
    ;
in
let
  # Given a feature definition, check its schema and return it if valid
  parseFeatureDefinition = # ... -> AttrSet | Feature definition that satifies the schema
    efLib: # AttrSet | Collection of utility functions to be passed to the feature
    extraArgs: # AttrSet | Extra arguments to be used by the feature
    featureDef: # AttrSet -> AttrSet | Target feature definition
    let
      featureArgs = {
        inherit lib efLib extraArgs;
      };
      result = lib.evalModules {
        modules = lib.singleton {
          options = featureOption;
          config = featureDef featureArgs;
        };
      };
    in
    result.config;
in
{
  inherit
    parseFeatureDefinition
    ;
}
