{ lib, use, ... }:
let
  inherit (use "parser.options")
    parseWithOption
    ;
in
let
  # Given a computation result, validate its inner content using additional schemas
  validateComputationResult =
    {
      valueSchema, # AttrSet | Option declaration or tree of feature's output value
      extensionSchemas, # AttrSet | Option declaration or tree of other features' extensions used here
      featureName, # AttrSet | Feature name from which this computation result comes
    }:
    computationResult: # AttrSet | Computation result passed outer schema validation
    let
      validValue =
        let
          # Make sure `parseWithOption` always receives an option tree rather a naked option.
          valueOptionTree = {
            value = valueSchema;
          };
          # Same shape with above.
          valueConfig = {
            value = computationResult.value;
          };

          result = parseWithOption {
            options = valueOptionTree;
            location = "<ef-computation:feature='${featureName}',scope='value'>";
          } valueConfig;
        in
        result.value;

      validExtensions = lib.flip lib.attrsets.mapAttrs computationResult.extensions (
        otherFeatureName: otherExtensionAttrs:
        lib.flip lib.attrsets.mapAttrs otherExtensionAttrs (
          otherExtensionName: extensionContent:
          let
            otherFeatureExtensionSchemas =
              extensionSchemas.${otherFeatureName}
                or (builtins.throw "schemas for feature '${otherFeatureName}' don't exist or that feature is not declared in `extends`");
            otherExtensionSchema =
              otherFeatureExtensionSchemas.${otherExtensionName}
                or (builtins.throw "schema for extension '${otherExtensionName}' from '${otherFeatureName}' doesn't exist");

            extensionOptionTree = {
              extension = otherExtensionSchema;
            };
            extensionConfig = {
              extension = extensionContent;
            };

            result = parseWithOption {
              options = extensionOptionTree;
              location = "<ef-computation:feature='${featureName}',scope='extension',to='${otherFeatureName}',extension='${otherExtensionName}'>";
            } extensionConfig;
          in
          result.extension
        )
      );

      result = computationResult // {
        value = validValue;
        extensions = validExtensions;
      };
    in
    result;
in
{
  inherit
    validateComputationResult
    ;
}
