{ lib, use, ... }:
let
  efLib = {
    inherit
      useExplicitly
      useImplicitly
      ;
  };

  useExplicitly = name: {
    inherit name;
    isExplicit = true;
  };

  useImplicitly = name: {
    inherit name;
    isExplicit = false;
  };
in
{
  inherit
    efLib
    useExplicitly
    useImplicitly
    ;
}
