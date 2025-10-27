{ nixosModules, ... }:
{ pkgs, ... }:
{
  imports = [ nixosModules.proxy ];

  config = {
    networking.hostName = "proxy";
    services.openssh.ports = [ 2222 ];

    yensid.proxy = {
      enable = true;
      builders = {
        builder1.ip = "builder1";
        builder2.ip = "builder2";
      };
      loadBalancing.strategy = "leastconn";
      # Or, for example:
      # loadBalancing.strategy = "custom";
      # loadBalancing.backendName = "only-builder-1";
      # loadBalancing.lua = pkgs.writeText "custom-balancing.lua" ''
      #   core.register_fetches('only-builder-1', function(txn)
      #     return "builder1"
      #   end)
      # '';
    };
  };
}
