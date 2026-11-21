{ lib, use }:
let
  inherit (use "parser.options")
    parseWithOption
    ;
  inherit (use "parser.options.computation")
    computationOption
    ;
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
    in
    parseWithOption featureOption (featureDef featureArgs);

  # Given a feature computation's result, check its schema and return it if valid
  parseFeatureComputation = # ... -> AttrSet | Valid computation result
    computationResult: # AttrSet | Raw computation result
    parseWithOption computationOption computationResult;
in
{
  inherit
    parseFeatureComputation
    parseFeatureDefinition
    ;
}
