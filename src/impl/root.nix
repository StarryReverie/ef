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
      enabledFeatures, # [String] | All explicitly enabled features' names
      extraArgs ? { }, # AttrSet | Extra arguments to pass to features
    }:
    allRawFeatures: # AttrSet | All parsed feature definitions
    let
      allFeatures = lib.attrsets.mapAttrs (
        name: rawFeature:
        parseFeatureDefinition {
          inherit efLib;
          inherit extraArgs;
          featureName = name;
        } rawFeature
      ) allRawFeatures;

      result = runFeatureComputations {
        explicitlyEnabledFeatureNames = enabledFeatures;
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
          inherit featureName;
          inherit extensionSchemas;
          computedResults = result;
          requiredFeatureNames = featureNode.required;
          extendingFeatureNames = featureNode.extendedBy;
        } allFeatures.${featureName}
      ) graph;
    in
    {
      inherit result;
      internal = {
        inherit graph;
      };
    };

  # If the effects are Nix modules, add more metadata to them and merge each kind of modules to a
  # single module. Applying this function to non Nix modules is undefined.
  effectsToNixModules =
    runResult: # AttrSet | Result of `runFeatures`
    let
      effectKindSet = lib.attrsets.mergeAttrsList (
        lib.mapAttrsToList (_: result: lib.attrsets.mapAttrs (_: _: true) result.effects) runResult.result
      );

      addFeatureTag =
        featureName: effectKind:
        lib.modules.setDefaultModuleLocation "<ef-computation:feature='${featureName}',scope='effect',kind='${effectKind}'>";

      taggedEffects = lib.attrsets.mapAttrsToList (
        featureName: result:
        lib.attrsets.mapAttrs (effectKind: addFeatureTag featureName effectKind) result.effects
      ) runResult.result;

      mergedEffects = lib.attrsets.mapAttrs (effectKind: _: {
        imports = lib.attrsets.catAttrs effectKind taggedEffects;
      }) effectKindSet;
    in
    mergedEffects;
in
{
  inherit
    runFeatures
    effectsToNixModules
    ;
}
