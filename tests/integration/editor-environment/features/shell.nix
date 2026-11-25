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

  computation = { requisites, extensions, ... }: {
    value = {
      aliases = lib.attrsets.concatMapAttrs (_: lib.id) extensions."aliases";

      profile = lib.pipe extensions."profile" [
        lib.attrsets.attrValues
        (lib.lists.sortOn (p: p.priority))
        (lib.strings.concatMapStringsSep "\n" (p: p.content))
      ];
    };
  };
}
