{ config, lib, ... }: {
  options.zzz.proxy = {
    enable = lib.mkEnableOption "Enable this machine as a proxy";

    builders = let
      builder = lib.types.submodule {
        options = {
          name = lib.mkOption { type = lib.types.str; };
          ip = lib.mkOption { type = lib.types.str; };
          port = lib.mkOption { type = lib.types.port; default = 22; };
        };
      };
    in lib.mkOption { type = lib.types.listOf builder; };
  };

  config = let cfg = config.zzz.proxy; in lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 22 ];
    services.haproxy = {
      enable = true;
      config = ''
        defaults
          log global
          mode tcp
          timeout connect 10s
          timeout client 36h
          timeout server 36h

        listen ssh
          bind *:22
          balance leastconn
          mode tcp

          option tcp-check
          tcp-check expect rstring SSH-2.0-OpenSSH.*

          ${lib.concatMapStrings (builder: ''
            server ${builder.name} ${builder.ip}:${toString builder.port} check inter 10s fall 2 rise 1
          '') cfg.builders}
      '';
    };
  };
}
