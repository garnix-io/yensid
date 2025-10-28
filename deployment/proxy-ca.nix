{ nixosModules, agenix, garnix-lib, ... }:
{ config, ... }:
{
  imports = [
    nixosModules.proxy
    nixosModules.ca
    agenix.nixosModules.default
    garnix-lib.nixosModules.garnix
  ];

  config = {
    networking.hostName = "proxy";
    services.openssh.ports = [ 2222 ];

    garnix.server.enable = true;

    # TODO: change this to your key if you want to be able to SSH into the
    # proxy itself (port 2222)
    users.users.root.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIVpNqdbM7uE1xkKoXztoaAtKtDHoqHS3DrzxYKsDgxa jkarni@garnix.io"
    ];

    yensid = {
      proxy = {
        enable = true;
        # Change this to the addresses of your builder
        builders = {
          builder1.ip = "142.132.141.88";
          builder2.ip = "142.132.141.89";
        };
        loadBalancing.strategy = "leastconn";
        # Or, for example:
        # loadBalancing.strategy = "custom";
        # loadBalancing.luaFile = pkgs.writeText "custom-balancing.lua" ''
        #   core.register_fetches('custom-strategy', function(txn)
        #     return "builder1"
        #   end)
        # '';
      };
      ca = {
        # TODO if you want certificate-authentication, enable this, and add
        # your builders below
        enable = false;
        builders = { };
      };
    };

    age.identityPaths = [
     "/var/garnix/keys/repo-key"
    ];
    age.secrets = {
      ca.file = ./ca.age;
      hostKey.file = ./hostKey.age;
    };

    environment.etc = {
      "ca-signing-key/ca-signing-key" = {
        source = config.age.secrets.ca.path;
        mode = "660";
        group = "signers";
      };
      "ssh/ssh_host_ed25519_key" = {
        source = config.age.secrets.hostKey.path;
        mode = "700";
      };
    };
  };
}
