{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  inputs.agenix.url = "github:ryantm/agenix";
  inputs.garnix-lib.url = "github:garnix-io/garnix-lib";
  inputs.nixos-compose.url = "github:garnix-io/nixos-compose";

  outputs =
    {
      self,
      nixpkgs,
      agenix,
      garnix-lib,
      nixos-compose,
      ...
    }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      lib = nixpkgs.lib;
    in
    {
      checks.x86_64-linux.mainTest = import ./tests/load-balancing.nix { inherit pkgs lib; };
      devShells.x86_64-linux.default = pkgs.mkShell {
        buildInputs = [
          agenix.packages.x86_64-linux.default
          nixos-compose.packages.x86_64-linux.default
        ];
      };

      nixosModules = {
        builder = ./modules/builder.nix;
        ca = ./modules/ca.nix;
        proxy = ./modules/proxy.nix;
      };

      nixosConfigurations =
        lib.mapAttrs
          (
            _: system:
            nixpkgs.lib.nixosSystem {
              modules = [
                {
                  nixpkgs.hostPlatform = "x86_64-linux";
                  system.stateVersion = "25.05";
                }
                (import system {
                  nixosModules = self.nixosModules;

                  inherit agenix;
                  inherit garnix-lib;

                  installTestKey = keyFile: {
                    source = keyFile;
                    mode = "700";
                  };
                })
              ];
            }
          )
          {
            ca = ./systems/ca.nix;
            client = ./systems/client.nix;
            proxy = ./systems/proxy.nix;
            builder1 = ./systems/builder1.nix;
            builder2 = ./systems/builder2.nix;
            deployment = ./deployment/proxy-ca.nix;
          };

    apps.x86_64-linux = {
      deployProxyViaGarnix = {
        type = "app";
        program = lib.getExe (pkgs.writeShellApplication {
          name = "deploy-proxy-via-garnix";
          text = ./deployment/deploy.sh;
          runtimeInputs = [
            pkgs.coreutils
            pkgs.gnused
            agenix.packages.x86_64-linux.default
          ];
        });
      };
      optionDocs =
        let
          modules = import (pkgs.path + "/nixos/lib/eval-config.nix") {
            system = "x86_64-linux";
            modules = [
                ./modules/ca.nix
                ./modules/proxy.nix
                ./modules/builder.nix
            ];
          };
          cleanedModules = lib.filterAttrs (n: v: n == "yensid") modules.options;
          docs = pkgs.nixosOptionsDoc {
            options = cleanedModules;
        };
        in
          { type = "app";
            program = lib.getExe (pkgs.writeShellApplication {
              name = "module-options.md";
              text = ''
                cp ${docs.optionsCommonMark} docs/options.md
              '';
            });
          };
        };
    };
}
