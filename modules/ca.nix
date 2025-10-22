{ config, pkgs, lib, ... }: {
  options.zzz.ca = {
    enable = lib.mkEnableOption "Enable this machine as a certificate authority";
  };

  config = let cfg = config.zzz.ca; in lib.mkIf cfg.enable {

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "sign-host-key";
        runtimeInputs = [ pkgs.openssh ];
        text = ''
          tmp=$(mktemp -d)
          echo "$1" > "$tmp/host.pub"
          ssh-keygen -h -s /etc/ca-signing-key/ca-signing-key -I garnix-ca "$tmp"/host.pub
          cat "$tmp/host-cert.pub"
          rm -rf "$tmp"
        '';
      })
    ];
  };
}
