{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.yensid.ca = {
    enable = lib.mkEnableOption "Enable this machine as a certificate authority";
    builders =
      let
        builder = lib.types.submodule {
          options = {
            sshPubKeyFile = lib.mkOption {
              description = "Path to the builder's public SSH key.";
              type = lib.types.path;
            };
          };
        };
      in
      lib.mkOption {
        type = lib.types.attrsOf builder;
        description = "The list of builders.";
      };
  };

  config =
    let
      cfg = config.yensid.ca;
    in
    lib.mkIf cfg.enable {

      users.users = lib.mapAttrs' (
        builderName: cfg:
        lib.nameValuePair "builder-${builderName}" {
          isSystemUser = true;
          shell = pkgs.bash;
          group = "builder-${builderName}";
          extraGroups = [ "signers" ];
          openssh.authorizedKeys.keyFiles = [ cfg.sshPubKeyFile ];
        }
      ) cfg.builders;

      users.groups =
        (lib.mapAttrs' (builderName: _: lib.nameValuePair "builder-${builderName}" { }) cfg.builders)
        // {
          signers = { };
        };

      services.openssh = {
        enable = true;
        extraConfig = ''

          ${lib.concatMapAttrsStringSep "\n" (builderName: cfg: ''
            Match User builder-${builderName}
              AllowAgentForwarding no
              AllowTcpForwarding no
              PermitTunnel no
              X11Forwarding no
              ForceCommand sign-host-key ${cfg.sshPubKeyFile}
          '') cfg.builders}

        '';
      };

      environment.systemPackages = [
        (pkgs.writeShellApplication {
          name = "sign-host-key";
          runtimeInputs = [
            pkgs.openssh
            pkgs.coreutils
          ];
          text = ''
            tmp=$(mktemp -d)
            cat "$1" > "$tmp/host.pub"
            ssh-keygen -h -s /etc/ca-signing-key/ca-signing-key -V -1d:+1d -I garnix-ca "$tmp"/host.pub
            cat "$tmp/host-cert.pub"
            rm -rf "$tmp"
          '';
        })
      ];
    };
}
