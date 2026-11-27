{
  lib,
  efLib,
  extraArgs,
  ...
}:
{

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

  schemas.extensions."profile" = lib.mkOption {
    type = lib.types.lines;
  };

  computation = { requisites, extensions, ... }: {
    value = {
      aliases = extensions."aliases";

      profile = extensions."profile";
    };
  };
}
