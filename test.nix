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
  testSshKeys = let
    mkTestKey = name: rec {
      priv = pkgs.runCommand
        name
        { buildInputs = [ pkgs.openssh ]; }
        "mkdir $out && ssh-keygen -f $out/${name}";
      pub = toString (pkgs.runCommand "${name}.pub" {} "cp ${priv}/${name}.pub $out");
      install = dir: lib.getExe (pkgs.writeShellApplication {
        name = "install-key-${name}";
        text = ''
          cp -r ${priv} ${dir}
          chmod -R 700 ${dir}
        '';
      });
    };
  in {
    ca = mkTestKey "ca-signing-key";
    client = mkTestKey "client";
  };
in pkgs.testers.runNixOSTest {
  name = "mainTest";

  nodes = {
    client = { nodes, pkgs, ... }: {
      nix = {
        settings.substituters = lib.mkForce [ ];

        settings.max-jobs = 0;
        extraOptions = "experimental-features = nix-command flakes";
        distributedBuilds = true;
        buildMachines = [
          {
            sshUser = "builder-ssh";
            sshKey = "/root/.ssh/client";
            protocol = "ssh-ng";
            hostName = "cluster";
            systems = [ "x86_64-linux" ];
          }
        ];
      };

      environment.systemPackages = [(
        pkgs.writeShellApplication {
          name = "run-test-build";
          text = ''
            ${testSshKeys.client.install "/root/.ssh"}
            cp ${test-derivation} test-package.nix
            date > random
            nix build --file test-package.nix
            cat result
          '';
        }
      )];

      programs.ssh = {
        knownHosts.cluster = {
          publicKeyFile = testSshKeys.ca.pub;
          certAuthority = true;
        };
        extraConfig = ''
          Host cluster
            HostName ${nodes.proxy.networking.primaryIPAddress}
            HostKeyAlias cluster
        '';
      };
    };

    ca = {
      imports = [ ./modules/ca.nix ];
      config = {
        zzz.ca = { enable = true; };
        services.openssh.enable = true;
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

    builder1 = {
      imports = [ ./modules/builder.nix ];
      config = {
        zzz.builder = {
          enable = true;
          clientAuthorizedKeyFiles = [ testSshKeys.client.pub ];
        };
      };
    };

    builder2 = {
      imports = [ ./modules/builder.nix ];
      config = {
        zzz.builder = {
          enable = true;
          clientAuthorizedKeyFiles = [ testSshKeys.client.pub ];
        };
      };
    };
  };

  testScript = ''
    start_all()

    builder1.wait_for_unit("multi-user.target")
    builder2.wait_for_unit("multi-user.target")
    ca.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")
    proxy.wait_for_unit("multi-user.target")

    proxy.wait_for_unit("haproxy.service")

    def sign_builder_host_key(builder):
      # for some reason builders don't have the public host key at this
      # point? so we need to generate it from the private one.
      builder.succeed("ssh-keygen -yf /etc/ssh/ssh_host_ed25519_key > /etc/ssh/ssh_host_ed25519_key.pub")

      hostKey = builder.succeed("cat /etc/ssh/ssh_host_ed25519_key.pub")
      cert = ca.succeed("sign-host-key '" + hostKey + "'")
      builder.succeed("echo '" + cert + "' > /etc/ssh/ssh_host_ed25519_key-cert.pub")
      builder.succeed("systemctl restart sshd.service")

    ca.succeed("${testSshKeys.ca.install "/etc/ca-signing-key"}")
    sign_builder_host_key(builder1)
    sign_builder_host_key(builder2)

    client.succeed("run-test-build")
  '';
}
