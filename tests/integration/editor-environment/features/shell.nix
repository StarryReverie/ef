{
  lib,
  efLib,
  extraArgs,
  ...
}:
{
  name = "shell";

  schemas.value = {
    aliases = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
    };

    profile = lib.mkOption {
      type = lib.types.lines;
    };
  };

  schemas.extensions."aliases" = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
  };

  schemas.extensions."profile" = {
    content = lib.mkOption {
      type = lib.types.lines;
    };

    priority = lib.mkOption {
      type = lib.types.int;
    };
  };

  computation = { requisites, rawExtensions, ... }: {
    value = {
      aliases = lib.attrsets.concatMapAttrs (_: lib.id) rawExtensions."aliases";

      profile = lib.pipe rawExtensions."profile" [
        lib.attrsets.attrValues
        (lib.lists.sortOn (p: p.priority))
        (lib.strings.concatMapStringsSep "\n" (p: p.content))
      ];
    };
  };
}
