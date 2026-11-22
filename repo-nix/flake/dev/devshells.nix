{ config, inputs, ... }:
{
  perSystem =
    { system, pkgsDev, ... }:
    {
      devShells.default = pkgsDev.mkShellNoCC {
        packages = [
          pkgsDev.nix-unit
          pkgsDev.nixfmt
          pkgsDev.treefmt
        ];
      };
    };
}
