{ config, pkgs, lib, ... }: {
  options.zzz.builder = {
    enable = lib.mkEnableOption "Enable this machine as a remote builder";

    clientAuthorizedKeyFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      description = "A list of authorized public ssh-key files that should be allowed to build on this machine";
      default = [];
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

    services.openssh = {
      enable = true;
      extraConfig = ''
        HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
      '';
    };
  };
}
