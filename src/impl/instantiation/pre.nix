{ lib, use, ... }:
let
  # Collect a feature's required features' computation outputs
  collectRequisites = # ... -> AttrSet | Data to be passed as `requisites` to this feature
    computedResults: # AttrSet | Previously computed features' results
    requiredFeatureNames: # [String] | All required features' names
    lib.attrsets.genAttrs requiredFeatureNames (
      featureName:
      let
        featureResult =
          computedResults.${featureName}
            or (builtins.throw "unreachable: computation result of '${featureName}' doesn't exist");
      in
      featureResult.value
    );

  # Collect a feature's extension data from other features.
  collectExtensions = # ... -> AttrSet | Data to be passed as `extensions` to this feature
    computedResults: # AttrSet | Previously computed features' results
    extendingFeatureNames: # [String] | All names of features that extend this feature
    currentFeatureName: # String | This feature's name
    extensionNames: # [String] | This feature's all extension points' names
    let
      extractExtensionToOptionals =
        extensionName: otherFeatureName:
        let
          featureResult =
            computedResults.${otherFeatureName}
              or (builtins.throw "unreachable: computation result of '${otherFeatureName}' doesn't exist");
          extensionsAttrs = featureResult.extensions;
        in
        if lib.attrsets.hasAttrByPath [ currentFeatureName extensionName ] extensionsAttrs then
          lib.singleton {
            name = otherFeatureName;
            value = extensionsAttrs.${currentFeatureName}.${extensionName};
          }
        else
          [ ];
    in
    lib.attrsets.genAttrs extensionNames (
      extensionName:
      lib.pipe extendingFeatureNames [
        (lib.lists.concatMap (extractExtensionToOptionals extensionName))
        lib.attrsets.listToAttrs
      ]
    );
in
{
  inherit
    collectExtensions
    collectRequisites
    ;
}
