{ config, lib, pkgs, ... }:

let
  cfg = config.programs.reliquary-archiver;
  pkg = pkgs.callPackage ./package.nix {};
in
{
  options.programs.reliquary-archiver = {
    enable = lib.mkEnableOption "reliquary-archiver";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkg ];

    security.wrappers.reliquary-archiver = {
      owner = "root";
      group = "root";
      capabilities = "cap_net_raw+ep";
      source = "${pkg}/bin/reliquary-archiver";
    };
  };
}
