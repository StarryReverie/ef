{ lib, inputs, ... }:
{
  flake.libTests = import ../../../tests/unit.nix {
    lib = inputs.nixpkgs.lib;
  };

  perSystem =
    { system, pkgsDev, ... }:
    let
      integrationTests = import ../../../tests/integration.nix {
        inherit inputs system;
        pkgs = pkgsDev;
      };
    in
    {
      legacyPackages.integrationTests = integrationTests;

      checks = lib.attrsets.mapAttrs' (
        name: case: lib.attrsets.nameValuePair "integration-test-${name}" case.test
      ) integrationTests;
    };
}
