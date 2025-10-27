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

    yensid = {
      proxy = {
        enable = true;
        builders = {
          # Change this to the IP addresses of your builder
          builder1.ip = "builder1";
          builder2.ip = "builder2";
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
        enable = true;
        # TODO add your builders here
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
