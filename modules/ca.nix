{ config, pkgs, lib, ... }: {
  options.zzz.ca = {
    enable = lib.mkEnableOption "Enable this machine as a certificate authority";
    builders =
      let builder = lib.types.submodule {
        options = {
          sshPubKeyFile = lib.mkOption {
            description = "Path to the builder's public SSH key.";
            type = lib.types.path;
          };
        };
      };
      in lib.mkOption { type = lib.types.attrsOf builder; };
  };

  config = let cfg = config.zzz.ca; in lib.mkIf cfg.enable {

    users.users = lib.mapAttrs' (builderName: cfg:
      lib.nameValuePair "builder-${builderName}"
      {
        isSystemUser = true;
        shell = pkgs.bash;
        group = "builder-${builderName}";
        extraGroups = [ "signer" ];
        openssh.authorizedKeys.keyFiles = [ cfg.sshPubKeyFile ];
      }) cfg.builders;

    users.groups = lib.mapAttrs' (builderName: _:
      lib.nameValuePair "builder-${builderName}" {}
    ) cfg.builders;

    services.openssh =
      {
        enable = true;
        extraConfig = ''

          ${lib.concatMapAttrsStringSep "\n" (builderName: cfg: ''
            Match User builder-${builderName}
              AllowAgentForwarding no
              AllowTcpForwarding no
              PermitTunnel no
              X11Forwarding no
              ForceCommand sign-host-key ${builtins.readFile cfg.sshPubKeyFile}
          '') cfg.builders}

        '';
      };

    # We need a setuid so the CA file can be used.
    security.wrappers."sign-host-key" = {
      setuid = true;
      owner = "root";
      group = "signer";
      permissions = "u+rx,g+x";
      source = lib.getExe (pkgs.writeShellApplication {
        name = "sign-host-key";
        runtimeInputs = [ pkgs.openssh pkgs.coreutils ];
        text = ''
          tmp=$(mktemp -d)
          echo "$1" > "$tmp/host.pub"
          ssh-keygen -h -s /etc/ca-signing-key/ca-signing-key -I garnix-ca "$tmp"/host.pub
          cat "$tmp/host-cert.pub"
          rm -rf "$tmp"
        '';
      });
    };
  };
}
