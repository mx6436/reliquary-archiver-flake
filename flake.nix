{
  description = "IceDynamix/reliquary-archiver Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        formatter = pkgs.nixfmt-tree;
        packages.default = pkgs.callPackage ./package.nix { };
      }
    )
    // {
      overlays.default = final: prev: {
        reliquary-archiver = self.packages.${final.stdenv.hostPlatform.system}.default;
      };

      nixosModules.default =
        { pkgs, ... }:
        {
          imports = [ ./module.nix ];
          _module.args.reliquary-archiver = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
    };
}
