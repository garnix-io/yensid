{ nixosModules, agenix, garnix-lib, ... }:
{ config, ... }:
{
  imports = [
    nixosModules.builder
    agenix.nixosModules.default
    garnix-lib.nixosModules.garnix
  ];

  config = {
    networking.hostName = "builder";
    garnix.server.enable = true;
    yensid.builder = {
      enable = true;
      name = "builder1";
      clientAuthorizedKeyFiles = [  ];
      caDomain = "ca";
      caHostKey = ../tests/fixtures/caHostKey.pub;
      sshClientKey = "/etc/ssh/ssh_host_ed25519_key";
    };
    environment.etc."ssh/ssh_host_ed25519_key" = {
      source = config.age.secrets.builderHostKey.path;
      mode = "7000";
    };
    age.identityPaths = [
     "/var/garnix/keys/repo-key"
    ];
    age.secrets = {
      builderHostKey.file = ./builderHostKey.age;
    };
  };
}

