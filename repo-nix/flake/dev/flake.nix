{
  description = "ef - a fairy tale of modules (Development)";

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

  # Development only.
  inputs.flake-compat = {
    url = "https://git.lix.systems/lix-project/flake-compat/archive/main.tar.gz";
    flake = false;
  };

  inputs.nix-maid = {
    url = "https://codeberg.org/viperML/nix-maid/archive/master.tar.gz";
  };

  outputs = _inputs: { };
}
