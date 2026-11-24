# ef-edsl

> ef - a fairy tale of modules

ef is an eDSL over Nix module system.

## Overview

We NixOS users all write NixOS configurations using the Nix module system and existing libraries such as `nixpkgs/nixos` and Home Manager. As the configuration evolves, the drawbacks of the Nix module system emerges gradually and we can hardly manage these tightly coupled "modules".

ef is designed to solve some of Nix module system's shortcomings by adding an additional abstraction layer over it while making use of the existing infrastructure. In short, ef has the following benefits:

- Loosely coupled unit of configurations
- Separation of high-level logics and low-level primitives
- Explicit dependency relationship and data flow
- Minimal and composable
- Compatible with both flake and non-flake

## Concepts

### Features

ef actually stands for *effectful feature*. In ef, a *feature* is a computation that can produce values and effects. Values can be passed to and consumed by other features, while *effects* are something represented using primitives of the underlying layer, for example, NixOS or Home Manager modules.

```nix
{ lib, efLib, ... }:
{
  name = "users/starryreverie/core/environment";

  requires = [ (efLib.useExplicitly "system/constant") ];
  extends = [ "users/starryreverie/core/shell" ];

  schemas.value = {
    envFile = lib.mkOption { type = lib.types.str; };
  };
  schemas.extensions."variables" = {
    anySession = lib.mkOption { type = lib.types.attrsOf lib.types.str; };
    graphicalSession = lib.mkOption { type = lib.types.attrsOf lib.types.str; };
  };

  computation = { requisites, extensions, ... }: {
    value = {
      envFile = "~/.config/environment.d/60-custom-user-environment.conf";
    };
    extensions."users/starryreverie/core/shell".profile = {
      content = "...";
      priority = 500;
    };

    effects."nixos" = { config, pkgs, ... }: {
      # I like using `nix-maid` to configure my home.
      users.users.starryreverie.maid = {
        # Actually should do something using `extensions."variables".<otherFeatureName>.<...>`
        file.xdg_config."environment.d/60-custom-user-environment.conf".text = "...";
      };
    };
  };
}
```

Each feature should have a unique identifier, which is specified by the `name` field.

A feature declares its dependency relationship using `requires` and `extends`. If feature `A` `requires` feature `B`, then feature `A` can use feature `B`'s computation result value as its input. If feature `C` `extends` feature `D`, then feature `D` can receive feature `C`'s extension data complied with its own schema definition.

A feature defines the types (a.k.a. schemas) of its computation value and the extension data it will receive. `schemas.value` specifies the shape of computation value, while `schemas.extensions.<extensionName>` is for each extension point. A feature only has a single output value but can have multiple extension points. All these type definitions use existing Nix module option types to do the validation, so you can set `schema.value` to a naked `lib.mkOption { ... }` or an option tree `{ someValue = lib.mkOption { ... }; ... }`.

The `computation` function is how a feature produces its value and effects. This function accepts at least two parameters `requisites` and `extensions`. `requisites` contains values of all features required by the current feature. `extensions` consist of other features' extension data to the current feature, grouped by this feature's extension point name and other feature's name. The result of the `computation` function consists of `value`, `extensions` and `effects`.

The canonical schema definitons of feature and feature's computation result are [`feature.nix`](./src/impl/parser/options/feature.nix) and [`computation.nix`](./src/impl/parser/options/computation.nix)
