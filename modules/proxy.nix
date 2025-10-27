{ config, lib, ... }:
{
  options.yensid.proxy = {
    enable = lib.mkEnableOption "Enable this machine as a proxy";

    builders =
      let
        builder = lib.types.submodule {
          options = {
            ip = lib.mkOption {
              type = lib.types.str;
              description = "IP address of builder";
            };
            port = lib.mkOption {
              type = lib.types.port;
              default = 22;
              description = "The port to use when connecting to the builder.";
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

      luaFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to a lua file to load. It should register a fetch named 'custom-strategy'";
        example = lib.literalExpression ''
          pkgs.writeText "test.lua" ${"''"}
            core.register_fetches('custom-strategy', function(txn)
              return "name-of-backend"
            end)
          ${"''"}
        '';
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
          assertion = cfg.loadBalancing.luaFile == null || cfg.loadBalancing.strategy == "custom";
          message = "loadBalancing.luaFile requires strategy custom";
        }
        {
          assertion = cfg.loadBalancing.luaFile != null || cfg.loadBalancing.strategy != "custom";
          message = "loadBalancing strategy custom requires setting luaFile";
        }
      ];

      networking.firewall.allowedTCPPorts = [ 22 ];
      services.haproxy = {
        enable = true;
        config = ''
          global
           ${lib.optionalString (cfg.loadBalancing.luaFile != null) "lua-load ${cfg.loadBalancing.luaFile}"}

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
              if cfg.loadBalancing.strategy == "custom" then
                ''
                  use_backend %[lua.custom-strategy]
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
