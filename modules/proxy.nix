{ config, lib, ... }:
{
  options.yensid.proxy = {
    enable = lib.mkEnableOption "Enable this machine as a proxy";

    builders =
      let
        builder = lib.types.submodule {
          options = {
            ip = lib.mkOption { type = lib.types.str; };
            port = lib.mkOption {
              type = lib.types.port;
              default = 22;
            };
          };
        };
      in
      lib.mkOption { type = lib.types.attrsOf builder; };

    loadBalancing = {
      strategy = lib.mkOption {
        type = lib.types.oneOf [
          (lib.types.strMatching "leastconn")
          (lib.types.strMatching "roundrobin")
          (lib.types.strMatching "source")
          (lib.types.strMatching "custom")
        ];
        default = "leastconn";
      };

      lua = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a lua file to load";
        example = lib.literalExpression ''
          pkgs.writeText "test.lua" ${"''"}
            core.register_fetches('my-load-balanced-backend', function(txn)
              return "name-of-backend"
            end)
          ${"''"}
        '';
      };

      backendName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Name of the backend registered by the lua program";
        example = "my-load-balanced-backend";
      };
    };
  };

  config =
    let
      cfg = config.yensid.proxy;
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.loadBalancing.lua == null || cfg.loadBalancing.strategy == "custom";
          message = "loadBalancing.lua requires strategy custom";
        }
        {
          assertion = cfg.loadBalancing.backendName == null || cfg.loadBalancing.strategy == "custom";
          message = "loadBalancing.backendName requires strategy custom";
        }
        {
          assertion = cfg.loadBalancing.backendName != null || cfg.loadBalancing.strategy != "custom";
          message = "loadBalancing strategy custom requires setting backendName";
        }
        {
          assertion = cfg.loadBalancing.lua != null || cfg.loadBalancing.strategy != "custom";
          message = "loadBalancing strategy custom requires setting lua";
        }
      ];

      networking.firewall.allowedTCPPorts = [ 22 ];
      services.haproxy = {
        enable = true;
        config = ''
          global
           ${lib.optionalString (cfg.loadBalancing.lua != null) "lua-load ${cfg.loadBalancing.lua}"}

          defaults
            log global
            mode tcp
            timeout connect 10s
            timeout client 36h
            timeout server 36h

          listen ssh
            bind *:22
            mode tcp
            option tcp-check
            tcp-check expect rstring SSH-2.0-OpenSSH.*
            ${
              if cfg.loadBalancing.backendName != null then
                ''
                  use_backend %[lua.${cfg.loadBalancing.backendName}]
                ''
              else
                ''
                  balance ${cfg.loadBalancing.strategy}
                  use_backend all
                ''
            }

          backend all
            ${lib.concatMapAttrsStringSep "" (
              name:
              { ip, port }:
              ''
                server ${name} ${ip}:${toString port} check inter 10s fall 2 rise 1
              ''
            ) cfg.builders}

          ${lib.concatMapAttrsStringSep "" (
            name:
            { ip, port }:
            ''
              backend ${name}
                server ${name} ${ip}:${toString port} check inter 10s fall 2 rise 1
            ''
          ) cfg.builders}
        '';
      };
    };
}
