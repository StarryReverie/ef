{ lib, use, ... }:
let
  # The utility functions passed to the feature
  efLib = {
    inherit
      useExplicitly
      useImplicitly
      anyOption
      ;
  };

  # Declare an explicit feature dependency in `requires`. When the current feature is explicitly
  # enabled, the dependent feature should also be enabled explicitly. However, if the current
  # feature is implicitly enabled via other feature's `useImplicitly`, the dependent feature needn't
  # to be declared to be enabled.
  useExplicitly = # ... -> [{ name :: String, isExplicit :: Bool }] | The underlying declaration
    name: # Name of the dependent feature
    {
      inherit name;
      isExplicit = true;
    };

  # Declare an implicit feature dependency in `requires`. When the current feature is enabled, this
  # dependent feature will also be enabled.
  useImplicitly = # ... -> [{ name :: String, isExplicit :: Bool }] | The underlying declaration
    name: # Name of the dependent feature
    {
      inherit name;
      isExplicit = false;
    };

  # An option type that allows anything to be assigned. Useful if you don't want to bother defining
  # strict schemas for your feature's result.
  anyOption = # Option | The option type declaration
    lib.mkOption {
      type = lib.types.raw;
      description = "Anything";
    };
in
{
  inherit
    efLib
    useExplicitly
    useImplicitly
    ;
}
