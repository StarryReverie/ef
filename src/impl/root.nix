{ lib, use, ... }:
let
  inherit (use "dependency")
    makeDependencyGraph
    ;
  inherit (use "dsl")
    efLib
    ;
  inherit (use "instantiation")
    instantiateFeature
    ;
  inherit (use "parser")
    parseFeatureDefinition
    ;
in
let
  runFeatures = # ... -> AttrSet | Computation result of all features
    {
      explicitlyEnabledFeatureNames, # [String] | All explicitly enabled features' names
      extraArgs, # AttrSet | Extra arguments to pass to features
    }:
    allRawFeatures: # AttrSet | All parsed feature definitions
    let
      allFeatures = lib.attrsets.mapAttrs (
        _:
        parseFeatureDefinition {
          inherit efLib;
          inherit extraArgs;
        }
      ) allRawFeatures;

      result = runFeatureComputations {
        inherit explicitlyEnabledFeatureNames;
      } allFeatures;
    in
    result;

  # Run each feature's computation in toposort order of dependency graph
  runFeatureComputations = # ... -> AttrSet | Computation result of all features
    {
      explicitlyEnabledFeatureNames, # [String] | All explicitly enabled features' names
    }:
    allFeatures: # AttrSet | All parsed feature definitions
    let
      graph = makeDependencyGraph allFeatures explicitlyEnabledFeatureNames;

      extensionSchemas = lib.attrsets.mapAttrs (_: feature: feature.schemas.extensions) allFeatures;

      result = lib.attrsets.mapAttrs (
        featureName: featureNode:
        instantiateFeature {
          inherit extensionSchemas;
          computedResults = result;
          requiredFeatureNames = featureNode.required;
          extendingFeatureNames = featureNode.extendedBy;
        } allFeatures.${featureName}
      ) graph;
    in
    result;
in
{
  inherit
    runFeatures
    ;
}
