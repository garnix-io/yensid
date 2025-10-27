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

    customLoadBalancing =
      let
        module = lib.types.submodule {
          options = {
            lua = lib.mkOption {
              type = lib.types.path;
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
              type = lib.types.str;
              description = "Name of the backend registered by the lua program";
              example = "my-load-balanced-backend";
            };
          };
        };
      in
      lib.mkOption {
        type = lib.types.nullOr module;
        default = null;
      };
  };

  config =
    let
      cfg = config.yensid.proxy;
    in
    lib.mkIf cfg.enable {
      networking.firewall.allowedTCPPorts = [ 22 ];
      systemd.services.haproxy.serviceConfig.StartLimitIntervalSec = 10;
      services.haproxy = {
        enable = true;
        config = ''
          global
           ${lib.optionalString (cfg.customLoadBalancing != null) "lua-load ${cfg.customLoadBalancing.lua}"}

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
              if cfg.customLoadBalancing == null then
                ''
                  balance leastconn
                  use_backend all
                ''
              else
                ''
                  use_backend %[lua.${cfg.customLoadBalancing.backendName}]
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
