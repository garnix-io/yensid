{ nixosModules, installTestKey, ... }:
{
  imports = [ nixosModules.builder ];

  config = {
    networking.hostName = "builder1";
    yensid.builder = {
      enable = true;
      name = "builder1";
      clientAuthorizedKeyFiles = [ ../tests/fixtures/clientSshKey.pub ];
      caDomain = "ca";
      caHostKey = ../tests/fixtures/caHostKey.pub;
      sshClientKey = "/etc/ssh/ssh_host_ed25519_key";
    };
    environment.etc."ssh/ssh_host_ed25519_key" = installTestKey ../tests/fixtures/builder1SshKey;
  };
}
