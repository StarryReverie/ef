{
  description = "ef - a tale of modules";

  inputs.flake-parts = {
    url = "github:hercules-ci/flake-parts/main";
    inputs.nixpkgs-lib = {
      follows = "nixpkgs";
    };
  };

  inputs.nixpkgs = {
    url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  inputs.systems = {
    url = "github:nix-systems/default/main";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;

      imports = [
        inputs.flake-parts.flakeModules.partitions
        ./repo-nix/flake
      ];

      partitions = {
        dev = {
          module = ./repo-nix/flake/dev;
          extraInputsFlake = ./repo-nix/flake/dev;
        };
      };

      partitionedAttrs = {
        checks = "dev";
        devShells = "dev";
        formatter = "dev";
        inputsDev = "dev";
        libTests = "dev";
      };
    };
}
