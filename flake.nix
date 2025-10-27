{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  outputs =
    { nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      lib = nixpkgs.lib;
    in
    {
      checks.x86_64-linux.mainTest = import ./tests/load-balancing.nix { inherit pkgs lib; };

      nixosConfigurations =
        let
          installTestKey = keyFile: {
            source = keyFile;
            mode = "700";
          };

          mkSystem =
            module:
            nixpkgs.lib.nixosSystem {
              modules = [
                module
                {
                  nixpkgs.hostPlatform = "x86_64-linux";
                  system.stateVersion = "25.05";
                }
              ];
            };
        in
        {
          client = mkSystem (
            { pkgs, ... }:
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
                environment.etc."ssh/client" = installTestKey ./tests/fixtures/clientSshKey;

                programs.ssh = {
                  knownHosts.cluster = {
                    publicKeyFile = ./tests/fixtures/caKey.pub;
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
          );

          ca = mkSystem {
            imports = [ ./modules/ca.nix ];
            config = {
              networking.hostName = "ca";
              yensid.ca = {
                enable = true;
                builders = {
                  builder1.sshPubKeyFile = ./tests/fixtures/builder1SshKey.pub;
                  builder2.sshPubKeyFile = ./tests/fixtures/builder2SshKey.pub;
                };
              };
              environment.etc = {
                "ca-signing-key/ca-signing-key" = {
                  source = ./tests/fixtures/caKey;
                  mode = "660";
                  group = "signers";
                };
                "ssh/ssh_host_ed25519_key" = installTestKey ./tests/fixtures/caHostKey;
              };
            };
          };

          proxy = mkSystem (
            { lib, ... }:
            {
              imports = [ ./modules/proxy.nix ];
              config = {
                networking.hostName = "proxy";
                services.openssh.ports = [ 2222 ];

                yensid.proxy = {
                  enable = true;
                  builders = {
                    builder1.ip = "builder1";
                    builder2.ip = "builder2";
                  };
                  customLoadBalancing.backendName = "only-builder-1";
                  customLoadBalancing.lua = pkgs.writeText "custom-balancing.lua" ''
                    core.register_fetches('only-builder-1', function(txn)
                      return "builder1"
                    end)
                  '';
                };
              };
            }
          );

          builder1 = mkSystem {
            imports = [ ./modules/builder.nix ];
            config = {
              networking.hostName = "builder1";
              yensid.builder = {
                enable = true;
                name = "builder1";
                clientAuthorizedKeyFiles = [ ./tests/fixtures/clientSshKey.pub ];
                caDomain = "ca";
                caHostKey = ./tests/fixtures/caHostKey.pub;
                sshClientKey = "/etc/ssh/ssh_host_ed25519_key";
              };
              environment.etc."ssh/ssh_host_ed25519_key" = installTestKey ./tests/fixtures/builder1SshKey;
            };
          };

          builder2 = mkSystem {
            imports = [ ./modules/builder.nix ];
            config = {
              networking.hostName = "builder2";
              yensid.builder = {
                enable = true;
                name = "builder2";
                clientAuthorizedKeyFiles = [ ./tests/fixtures/clientSshKey.pub ];
                caDomain = "ca";
                caHostKey = ./tests/fixtures/caHostKey.pub;
                sshClientKey = "/etc/ssh/ssh_host_ed25519_key";
              };
              environment.etc."ssh/ssh_host_ed25519_key" = installTestKey ./tests/fixtures/builder2SshKey;
            };
          };
        };
    };
}
