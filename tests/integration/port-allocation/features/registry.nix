{
  lib,
  efLib,
  extraArgs,
}:
{
  schemas.value = {
    ports = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.allocation = lib.mkOption { type = lib.types.port; };
          options.protocol = lib.mkOption {
            type = lib.types.enum [
              "tcp"
              "udp"
            ];
          };
        }
      );
    };
  };

  schemas.extensions."services" = lib.mkOption {
    type = lib.types.listOf (
      lib.types.submodule ({
        options.name = lib.mkOption { type = lib.types.str; };
        options.protocol = lib.mkOption {
          type = lib.types.enum [
            "tcp"
            "udp"
          ];
        };
      })
    );
  };

  computation = { requisites, extensions, ... }: {
    value = {
      ports = lib.attrsets.listToAttrs (
        lib.lists.imap0 (
          idx: service:
          lib.nameValuePair service.name {
            allocation = 8080 + idx;
            inherit (service) protocol;
          }
        ) extensions."services"
      );
    };
  };
}
