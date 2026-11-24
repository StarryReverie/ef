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
      extraArgs, # AttrSet | Extra arguments to pass to features
    }:
    allRawFeatures: # AttrSet | All parsed feature definitions
    let
      allFeatures = lib.attrsets.mapAttrs (lib.const (parseFeatureDefinition {
        inherit efLib;
        inherit extraArgs;
      })) allRawFeatures;

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
          inherit extensionSchemas;
          computedResults = result;
          requiredFeatureNames = featureNode.required;
          extendingFeatureNames = featureNode.extendedBy;
        } allFeatures.${featureName}
      ) graph;
    in
    result;

  # If the effects are Nix modules, add more metadata to them and merge each kind of modules to a
  # single module. Applying this function to non Nix modules is undefined.
  effectsToNixModules =
    runResult: # AttrSet | Result of `runFeatures`
    let
      effectKindSet = lib.attrsets.mergeAttrsList (
        lib.flip lib.mapAttrsToList runResult (_: result: lib.attrsets.mapAttrs (_: _: true) result.effects)
      );

      addFeatureTag =
        featureName: effectKind:
        lib.modules.setDefaultModuleLocation "<ef-computed:feature='${featureName}',effect='${effectKind}'>";

      taggedEffects = lib.attrsets.mapAttrsToList (
        featureName: result:
        lib.attrsets.mapAttrs (effectKind: addFeatureTag featureName effectKind) result.effects
      ) runResult;

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
