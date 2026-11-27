{ name, dist }:
{
  "${name}-service-metadata" = { lib, efLib, ... }: {
    extends = [
      "registry"
    ];

    schemas.value = {
      name = lib.mkOption { type = lib.types.str; };
    };

    computation = { requisites, extensions, ... }: {
      value = {
        inherit name;
      };

      extensions."registry"."services" = lib.singleton {
        inherit name;
        protocol = "tcp";
      };
    };
  };

  "${name}-server" = { lib, efLib, ... }: {
    requires = [
      (efLib.useImplicitly "${name}-service-metadata")
      (efLib.useExplicitly "registry")
    ];

    computation = { requisites, extensions, ... }: {
      effects."nixos" =
        { config, pkgs, ... }:
        let
          serviceName = requisites."${name}-service-metadata".name;
          servicePort = requisites."registry".ports."${serviceName}".allocation;
        in
        {
          systemd.services."${serviceName}" = {
            serviceConfig.ExecStart = "${lib.getExe pkgs.miniserve} --spa --index index.html --port ${toString servicePort} ${dist}";
            wantedBy = [ "multi-user.target" ];
          };

          environment.systemPackages = [
            (pkgs.writeShellApplication {
              name = "open-${serviceName}";
              text = ''
                url="http://127.0.0.1:${toString servicePort}/"
                if [ -t 1 ]; then
                  exec ${lib.getExe pkgs.lynx} "$url"
                else
                  exec ${lib.getExe pkgs.lynx} -dump -nolist "$url"
                fi
              '';
            })
          ];
        };
    };
  };
}
