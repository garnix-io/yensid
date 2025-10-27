{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  outputs =
    { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      lib = nixpkgs.lib;
    in
    {
      checks.x86_64-linux.mainTest = import ./tests/load-balancing.nix { inherit pkgs lib; };

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
          };

    apps.x86_64-linux.optionDocs =
      let
        modules = import (pkgs.path + "/nixos/lib/eval-config.nix") {
          system = "x86_64-linux";
          modules = [
              ./modules/ca.nix
              ./modules/proxy.nix
              ./modules/builder.nix
          ];
        };
        cleanedModules = lib.filterAttrs (n: v: n == "zzz") modules.options;
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
}
