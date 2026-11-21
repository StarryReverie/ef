{ lib, use }:
let
  inherit (use "parser.options")
    parseWithOption
    ;
in
let
  # Given a computation result, validate its inner content using additional schemas
  validateComputationResult =
    valueSchema: # AttrSet | Option declaration or tree of feature's output value
    extensionSchemas: # AttrSet | Option declaration or tree of other features' extensions used here
    featureName: # AttrSet | Feature name from which this computation result comes
    computationResult: # AttrSet | Computation result passed outer schema validation
    let
      validValue = builtins.addErrorContext "while validating the field 'value'" (
        let
          # Make sure `parseWithOption` always receives an option tree rather a naked option.
          valueOptionTree = {
            value = valueSchema;
          };
          # Same shape with above.
          valueConfig = {
            value = computationResult.value;
          };

          result = parseWithOption valueOptionTree valueConfig;
        in
        result.value
      );

      validExtensions = builtins.addErrorContext "while validating the field 'extensions'" (
        lib.flip lib.attrsets.mapAttrs computationResult.extensions (
          otherFeatureName: otherExtensionAttrs:
          lib.flip lib.attrsets.mapAttrs otherExtensionAttrs (
            otherExtensionName: extensionContent:
            let
              otherFeatureExtensionSchemas =
                extensionSchemas.${otherFeatureName}
                  or (builtins.throw "schemas for feature '${otherFeatureName}' don't exist");
              otherExtensionSchema =
                otherFeatureExtensionSchemas.${otherExtensionName}
                  or (builtins.throw "schema for extension '${otherExtensionName}' from '${otherFeatureName}' doesn't exist");
            in
            builtins.addErrorContext
              "while validating extension '${otherExtensionName}' from '${otherFeatureName}'"
              (
                let
                  extensionOptionTree = {
                    extension = otherExtensionSchema;
                  };
                  extensionConfig = {
                    extension = extensionContent;
                  };
                  result = parseWithOption extensionOptionTree extensionConfig;
                in
                result.extension
              )
          )
        )
      );

      result =
        builtins.addErrorContext "while validating the computation result of feature '${featureName}'"
          (
            computationResult
            // {
              value = validValue;
              extensions = validExtensions;
            }
          );
    in
    result;
in
{
  inherit
    validateComputationResult
    ;
}
