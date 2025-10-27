{ installTestKey, ... }:
{ pkgs, lib, ... }:
{
  config = {
    networking.hostName = "client";
    nix = {
      settings.substituters = lib.mkForce [ ];

      settings.max-jobs = 0;
      extraOptions = "experimental-features = nix-command flakes";
      distributedBuilds = true;
      buildMachines = [
        {
          sshUser = "builder-ssh";
          sshKey = "/etc/ssh/client";
          protocol = "ssh-ng";
          hostName = "cluster";
          systems = [ "x86_64-linux" ];
        }
      ];
    };
    environment.etc."ssh/client" = installTestKey ../tests/fixtures/clientSshKey;

    programs.ssh = {
      knownHosts.cluster = {
        publicKeyFile = ../tests/fixtures/caKey.pub;
        certAuthority = true;
      };
      extraConfig = ''
        Host cluster
          HostName proxy
          HostKeyAlias cluster
      '';
    };
  };
}
