# ef-edsl

> ef - a fairy tale of modules

ef is an eDSL over Nix module system.

## Overview

We NixOS users all write NixOS configurations using the Nix module system and existing libraries such as `nixpkgs/nixos` and Home Manager. As the configuration evolves, the drawbacks of the Nix module system emerge gradually and we can hardly manage these tightly coupled "modules".

ef is designed to solve some of Nix module system's shortcomings by adding an additional abstraction layer over it while making use of the existing infrastructure. In short, ef has the following benefits:

- Loosely coupled unit of configurations
- Separation of high-level logics and low-level primitives
- Explicit dependency relationship and data flow
- Minimal and composable
- Compatible with both flake and non-flake

## Getting Started

ef is available as a flake input. Without flakes, `(import "${sources.ef}/src/default.nix").mkLib { inherit lib; }` can be used to obtain the API, where `sources` contains a pinned revision of ef.

In ef, you need to write *feature*, the unit of configurations. Features are passed to `runFeatures`, and `effectsToNixModules` turns the resulting effects into Nix modules. The `.nixos` module is then passed to `lib.nixosSystem`:

```nix
# flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.ef.url = "github:StarryReverie/ef-edsl";
  inputs.ef.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { nixpkgs, ef, ... }:
    let
      features = {
        hello = import ./features/hello.nix;
      };
      # You can also use `ef.mkLib { lib = nixpkgs.lib; }` to get a `ef.lib`.
      runResult = ef.lib.runFeatures {
        enabledFeatures = [ "hello" ];
      } features;
    in
    {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (ef.lib.effectsToNixModules runResult).nixos
          ./configuration.nix
          ./hardware-configuration.nix
          # ...
        ];
      };
    };
}
```

A minimal feature adds a package through a NixOS effect:

```nix
# features/hello.nix
{ lib, efLib, ... }:
{
  name = "hello";
  computation = { requisites, extensions, ... }: {
    effects."nixos" = { config, pkgs, ... }: {
      environment.systemPackages = [ pkgs.hello ];
    };
  };
}
```

Please read the [Concepts](#Concepts) for more information.

## Examples

This repository uses integration test cases as the examples. Currently the following integration tests are available:

- [Minimal](./tests/integration/minimal/)
- [Editor Environment](./tests/integration/editor-environment/)

You can run the example a.k.a test using the following commands:

```bash
# Interactive NixOS VM
nix run '.#integrationTests.minimal.vm'
# NixOS VM test
nix build '.#integrationTests.minimal.test'
```

For non-flake users:

```bash
# Interactive NixOS VM
nix-build tests/integration.nix -A minimal.vm && ./result/bin/run-nixos-vm
# NixOS VM test
nix-build tests/integration.nix -A minimal.test
```

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

The `computation` function is how a feature produces its value and effects. This function accepts at least three parameters `requisites`, `extensions`, and `rawExtensions`. `requisites` contains values of all features required by the current feature. `rawExtensions` consists of other features' extension data to the current feature, grouped by this feature's extension point name and other feature's name. `extensions` is a merged version of `rawExtensions` without feature's name. The result of the `computation` function consists of `value`, `extensions` and `effects`.

The canonical schema definitons of feature and feature's computation result are [`feature.nix`](./src/impl/parser/options/feature.nix) and [`computation.nix`](./src/impl/parser/options/computation.nix)

### Dependency and Data Flow

Features can depend on other features. In ef, the dependency is strict. `requires` and `extends` declarations control what other features the current feature can depend on and extend. Features are not allowed to pass data to or from other features, if it doesn't declare its requisites in `requires` or extension targets in `extends`.

The dependency graph resolution needs you to provide a set of explicitly enabled features. Eventually all features included in the dependency closure are all enabled. In terms of `requires` and `extends` dependcy, only the former one will be taken into account when calculating the closure.

Dependency relationship introduced by `requires` has two kinds: `useExplicitly` and `useImplicitly`. If feature `A` requires feature `B` via `useExplicitly`, then feature `B` must also be enabled explicitly when feature `A` is enabled explicitly. In contrast, `useImplicitly` always enable a feature's dependencies if itself is enabled.

Dependency relationship of `extends` is passive. There is no relationship between whether two sides of a `extends` are enabled respectively or not.

Dependency graph must be a directed acyclic graph (DAG). Because I'm convinced that cyclic dependency is evil, which should be got rid of as an anti-pattern. Removing cycles from your feature graph makes it easier to reason about.

### Effects

Effects are generated from feature's `computation` functions. In theory, the feature can be modeled as a `Writer w a` monad where `w` is the effect and `a` is the pure computation result, as Nix modules are `Monoid`s and can be `<>`-ed using `lib.mkMerge` or `imports = [ ... ]`. However, it's almost impossible to implement the `Functor`/`Applicative`/`Monad` instance for features in *Fake Haskell Compiled into Bash* (Nix).

ef is designed to be an eDSL over Nix module system, so the most apparent usecase of effects is Nix modules. The `effects` field in the feature's computation result is an attrset whose key is the kind of Nix modules, such as `nixos` or `homeManager`. ef provides the function `effectsToNixModules` that helps merge Nix modules of the same kind into a single module for each kind, then you can pass it to e.g. `lib.evalModules`, `lib.nixosSystem`, and so on.

But ef is capable of producing other things as effects. You can return anythings from a `computation` function and merge them by yourselves.

## License

This project is licensed under the [MIT license](./LICENSE).

Copyright (C) 2026 Justin Chen
