{ config, pkgs, lib, ... }: {
  options.zzz.builder = {
    enable = lib.mkEnableOption "Enable this machine as a remote builder";

    clientAuthorizedKeyFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "A list of authorized public ssh-key files that should be allowed to build on this machine";
      default = [];
    };

    name = lib.mkOption {
      type = lib.types.str;
      description = "The name used for this builder in the SSH module.";
    };

    caDomain = lib.mkOption {
      type = lib.types.str;
      description = "The domain or IP address of the CA.";
    };

    caHostKey = lib.mkOption {
      type = lib.types.path;
      description = "The public key of the CA server";
    };

    caCertLocation = lib.mkOption {
      type = lib.types.str;
      description = "Where the CA signature lives";
      readOnly = true;
      default = "/etc/ssh/ssh_host_ed25519_key-cert.pub";
    };

    sshClientKey = lib.mkOption {
      type = lib.types.str;
      description = "Path of the client key to use to SSH into the CA.";
    };
  };

  config = let cfg = config.zzz.builder; in lib.mkIf cfg.enable {
    users.users.builder-ssh = {
      isSystemUser = true;
      shell = pkgs.bash;
      group = "users";
      openssh.authorizedKeys.keyFiles = cfg.clientAuthorizedKeyFiles;
      extraGroups = [ "wheel" ];
    };

    systemd.services.renewCASignature = {
      description = "Renew SSH key signature from CA";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      script = "${pkgs.openssh}/bin/ssh -i ${cfg.sshClientKey} builder-${cfg.name}@${cfg.caDomain} sign-host-key > ${cfg.caCertLocation}";
      serviceConfig = {
        Type = "oneshot";
        # The CA may not be reachable. If that's the case, we want a shorter
        # retry loop than the timer
        Restart = "on-failure";
        RestartSec = "100ms";
        RestartMaxDelaySec = "5min";
        RestartSteps = 20;
      };
      unitConfig = {
        StartLimitIntervalSec = 0;
        StartLimitBurst = 0;
      };
    };

    systemd.timers.renewCASignature = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5sec";
        OnUnitActiveSec = "5h";
        Persistent = true;
        Unit = "renewCASignature.service";
      };
    };

    programs.ssh.knownHosts.ca = {
      hostNames = [ cfg.caDomain ];
      publicKeyFile = cfg.caHostKey;
    };

    services.openssh = {
      enable = true;
      extraConfig = ''
        HostCertificate ${cfg.caCertLocation}
      '';
    };
  };
}
