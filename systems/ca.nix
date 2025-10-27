{ nixosModules, installTestKey, ... }:
{
  imports = [ nixosModules.ca ];

  config = {
    networking.hostName = "ca";
    yensid.ca = {
      enable = true;
      builders = {
        builder1.sshPubKeyFile = ../tests/fixtures/builder1SshKey.pub;
        builder2.sshPubKeyFile = ../tests/fixtures/builder2SshKey.pub;
      };
    };
    environment.etc = {
      "ca-signing-key/ca-signing-key" = {
        source = ../tests/fixtures/caKey;
        mode = "660";
        group = "signers";
      };
      "ssh/ssh_host_ed25519_key" = installTestKey ../tests/fixtures/caHostKey;
    };
  };
}
