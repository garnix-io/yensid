{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  outputs = { nixpkgs, ... }: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    lib = nixpkgs.lib;
  in {
    checks.x86_64-linux.mainTest = import ./test.nix { inherit pkgs lib; };
  };
}
