{ lib, use, ... }:
let
  efLib = {
    useExplicitly = name: {
      inherit name;
      isExplicit = true;
    };

    useImplicitly = name: {
      inherit name;
      isExplicit = false;
    };
  };
in
{
  inherit
    efLib
    ;
}
