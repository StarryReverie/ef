{ lib, use, ... }:
let
  inherit (use "parser.options")
    parseWithOption
    ;
in
let
  # Collect a feature's required features' computation outputs
  collectRequisites = # ... -> AttrSet | Data to be passed as `requisites` to this feature
    {
      requiredFeatureNames, # [String] | All required features' names
    }:
    computedResults: # AttrSet | Previously computed features' results
    lib.attrsets.genAttrs requiredFeatureNames (
      featureName:
      let
        featureResult =
          computedResults.${featureName}
            or (builtins.throw "unreachable: computation result of '${featureName}' doesn't exist");
      in
      featureResult.value
    );

  # Collect a feature's extension data from other features without merging.
  collectRawExtensions = # ... -> AttrSet | Data to be passed as `extensions` to this feature
    {
      extendingFeatureNames, # [String] | All names of features that extend this feature
      currentFeatureName, # String | This feature's name
      extensionNames, # [String] | This feature's all extension points' names
    }:
    computedResults: # AttrSet | Previously computed features' results
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

  # Merge the extension data from other features for each extension point using Nix module merging
  mergeRawExtensions =
    {
      extensionSchemas, # AttrSet | Extension schemas of all extension points
      featureName, # AttrSet | Feature name from which this computation result comes
    }:
    rawExtensions: # AttrSet | Extension data grouped by extension point and feature name
    lib.flip lib.attrsets.mapAttrs rawExtensions (
      extensionName: extensionValues:
      let
        extensionOptionTree = {
          extension =
            extensionSchemas.${extensionName}
              or (builtins.throw "unreachable: schema of extension '${extensionName}' doesn't exist");
        };
        extensionConfig = lib.mkMerge (
          lib.attrsets.mapAttrsToList (_: extensionValue: { extension = extensionValue; }) extensionValues
        );

        result = parseWithOption {
          options = extensionOptionTree;
          location = "<ef-computation-pre:feature='${featureName}',scope='extensionMerging',extension='${extensionName}'>";
        } extensionConfig;
      in
      result.extension
    );
in
{
  inherit
    collectRawExtensions
    collectRequisites
    mergeRawExtensions
    ;
}
