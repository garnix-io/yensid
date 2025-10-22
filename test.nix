{ pkgs, lib, ... }: let
  test-derivation = pkgs.writeText "test-package.nix" ''
    derivation {
      name = "test-package";
      system = "x86_64-linux";
      builder = "/bin/sh";
      args = ["-c" "echo ''${./random} > $out" ];
    }
  '';

  # For testing only, in production the keys would be generated on the
  # machine on first boot, then public keys only are populated in configs
  installTestKey = keyFile: {
    source = keyFile;
    mode = "700";
  };

in pkgs.testers.runNixOSTest {
  name = "mainTest";

  nodes = {
    client = { nodes, pkgs, ... }: {
      config = {
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
        environment.etc."ssh/client" = installTestKey ./test/clientSshKey;

        environment.systemPackages = [(
          pkgs.writeShellApplication {
            name = "run-test-build";
            text = ''
              cp ${test-derivation} test-package.nix
              date > random
              nix build --file test-package.nix
              cat result
            '';
          }
        )];

        programs.ssh = {
          knownHosts.cluster = {
            publicKeyFile = ./test/caKey.pub;
            certAuthority = true;
          };
          extraConfig = ''
            Host cluster
              HostName ${nodes.proxy.networking.primaryIPAddress}
              HostKeyAlias cluster
          '';
        };
       };
    };

    ca = {
      imports = [ ./modules/ca.nix ];
      config = {
        zzz.ca = {
          enable = true;
          builders = {
            builder1.sshPubKeyFile = ./test/builder1SshKey.pub;
            builder2.sshPubKeyFile = ./test/builder2SshKey.pub;
          };
        };
        environment.etc."ca-signing-key/ca-signing-key" = installTestKey ./test/caKey;
        environment.etc."ssh/ssh_host_ed25519_key" = installTestKey ./test/caHostKey;
      };
    };

    proxy = { nodes, ... }: {
      imports = [ ./modules/proxy.nix ];
      config = {
        zzz.proxy = {
          enable = true;
          builders = [
            { name = "builder1"; ip = nodes.builder1.networking.primaryIPAddress; }
            { name = "builder2"; ip = nodes.builder2.networking.primaryIPAddress; }
          ];
        };
      };
    };

    builder1 = { nodes, ... }: {
      imports = [ ./modules/builder.nix ];
      config = {
        zzz.builder = {
          enable = true;
          name = "builder1";
          clientAuthorizedKeyFiles = [ ./test/clientSshKey.pub ];
          caDomain = nodes.ca.networking.primaryIPAddress;
          caHostKey = ./test/caHostKey.pub;
          sshClientKey = "/etc/ssh/ssh_host_ed25519_key";
        };
        environment.etc."ssh/ssh_host_ed25519_key" = installTestKey ./test/builder1SshKey;
      };
    };

    builder2 = { nodes, ... }: {
      imports = [ ./modules/builder.nix ];
      config = {
        zzz.builder = {
          enable = true;
          name = "builder2";
          clientAuthorizedKeyFiles = [ ./test/clientSshKey.pub ];
          caDomain = nodes.ca.networking.primaryIPAddress;
          caHostKey = ./test/caHostKey.pub;
          sshClientKey = "/etc/ssh/ssh_host_ed25519_key";
        };
        environment.etc."ssh/ssh_host_ed25519_key" = installTestKey ./test/builder2SshKey;
      };
    };
  };

  testScript = ''
    import json

    start_all()

    builder1.wait_for_unit("multi-user.target")
    builder2.wait_for_unit("multi-user.target")
    ca.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")
    proxy.wait_for_unit("multi-user.target")
    proxy.wait_for_unit("haproxy.service")

    for system in [builder1, builder2, ca, client, proxy]:
        (_, failed_units_str) = system.systemctl("list-units --failed --output=json")
        failed_units = json.loads(failed_units_str)
        assert not failed_units, f"failed units: {', '.join([ unit['unit'] for unit in failed_units ])}"

    client.succeed("run-test-build")
  '';
}
