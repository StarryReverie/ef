{ lib, use, ... }:
let
  # Match a raw attrset against an option tree and return it if valid
  parseWithOption = # ... -> AttrSet | Valid value
    {
      options, # AttrSet | Option tree, i.e. value part of the conventional `options = { ... }`
      location, # String | Pesudo filename for this temporary module evaluation
    }:
    value: # AttrSet | Raw value
    let
      result = lib.evalModules {
        modules = lib.singleton {
          _file = location;
          inherit options;
          config = value;
        };
      };
    in
    result.config;
in
{
  inherit
    parseWithOption
    ;
}
