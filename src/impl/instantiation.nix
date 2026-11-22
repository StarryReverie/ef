{ lib, use, ... }:
let
  inherit (use "instantiation.post")
    validateComputationResult
    ;
  inherit (use "instantiation.pre")
    collectExtensions
    collectRequisites
    ;
  inherit (use "parser")
    parseFeatureComputation
    ;
in
let
  # Run a feature's computation and validate its result
  instantiateFeature = # ... -> AttrSet
    extensionSchemas: # AttrSet | Option declaration or tree of all features' extensions
    computedResults: # AttrSet | Previously computed features' results
    requiredFeatureNames: # [String] | All required features' names
    extendingFeatureNames: # [String] | All names of features that extend this feature
    feature: # AttrSet | Parsed feature definition
    let
      requisites = builtins.addErrorContext "while preparing requisites for feature '${feature.name}'" (
        collectRequisites computedResults requiredFeatureNames
      );
      extensions = builtins.addErrorContext "while preparing extensions for feature '${feature.name}'" (
        collectExtensions computedResults extendingFeatureNames feature.name (
          lib.attrsets.attrNames feature.schemas.extensions
        )
      );

      result =
        let
          rawResult = parseFeatureComputation (feature.computation { inherit requisites extensions; });

          filteredExtensionSchemas = lib.attrsets.genAttrs feature.extends (
            otherFeatureName:
            extensionSchemas.${otherFeatureName}
              or (builtins.throw "feature '${otherFeatureName}' extended by the current feature '${feature.name}' doesn't exist")
          );
        in
        builtins.addErrorContext "while evaluating computation of feature '${feature.name}'" (
          validateComputationResult feature.schemas.value filteredExtensionSchemas feature.name rawResult
        );
    in
    result;
in
{
  inherit
    instantiateFeature
    ;
}
