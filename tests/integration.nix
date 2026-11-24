{
  system ? builtins.currentSystem,
  pkgs ? (import ../.).inputs.nixpkgs.legacyPackages.${system},
  lib ? pkgs.lib,
}:
let
  efApi = import ../src/. { inherit lib; };

  entries = lib.flip lib.attrsets.concatMapAttrs (builtins.readDir ./integration) (
    name: type:
    lib.attrsets.optionalAttrs (type == "directory") ({
      ${name} = lib.fix (
        self:
        (import ./integration/${name}/entry-point.nix {
          inherit pkgs efApi;
        })
        // {
          vm = (pkgs.nixos self.module).config.system.build.vm;

          test = pkgs.testers.runNixOSTest {
            inherit name;
            imports = lib.singleton ({
              nodes.vm = self.module;
              testScript = self.testScript;
            });
          };
        }
      );
    })
  );
in
entries
