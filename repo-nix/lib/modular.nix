{
  lib,
  moduleDir,
  extraArgs ? { },
}:
let
  evaluate = x: builtins.seq x x;

  makeModuleTreeWithEnv =
    env: dir:
    let
      dirEntries = builtins.readDir dir;

      names = lib.lists.uniqueStrings (
        lib.flip lib.lists.concatMap (lib.attrsets.attrsToList dirEntries) (
          { name, value }:
          if value == "directory" then
            [ name ]
          else if value == "regular" && lib.strings.hasSuffix ".nix" name then
            [ (lib.strings.removeSuffix ".nix" name) ]
          else
            [ ]
        )
      );

      modules = lib.attrsets.listToAttrs (
        lib.flip lib.lists.map names (name: {
          inherit name;
          value =
            let
              children = lib.attrsets.optionalAttrs (lib.attrsets.hasAttr name dirEntries) (
                makeModuleTreeWithEnv env (dir + /${name}/.)
              );
            in
            if lib.attrsets.hasAttr "${name}.nix" dirEntries then
              rec {
                inherit children;
                path = dir + /${name}.nix;
                content = import path env;
              }
            else
              { inherit children; };
        })
      );
    in
    modules;

  makeModuleTree =
    dir:
    let
      moduleTree = makeModuleTreeWithEnv moduleEnv dir;

      moduleEnv = {
        inherit lib extraArgs;

        use =
          modulePath:
          let
            rawAttrPath = lib.strings.splitString "." modulePath;
            attrPath = (lib.intersperse "children" rawAttrPath) ++ [ "content" ];
            err = builtins.abort "module path \"${modulePath}\" doesn't exist";
          in
          evaluate (lib.attrsets.attrByPath attrPath err moduleTree);
      };

      evalModuleTree =
        tree:
        builtins.deepSeq (lib.flip lib.lists.map (lib.attrsets.attrValues tree) (
          mod: builtins.seq (builtins.seq (mod.content or { }) (evalModuleTree mod.children)) 1
        )) tree;
    in
    {
      inherit (moduleEnv) use;
      moduleTree = evalModuleTree moduleTree;
    };
in
makeModuleTree moduleDir
