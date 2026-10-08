{
  description = "Baidu Netdisk (百度网盘) — Nix flake for the official Linux client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-gtk2.url = "github:NixOS/nixpkgs/f13ff45afd1bb73e640eaa08a7066dbed07e3238";
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-gtk2,
      ...
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            system = system;
            config.allowUnfree = true;
          };
          pkgsGtk2 = import nixpkgs-gtk2 {
            system = system;
          };
          package = pkgs.callPackage ./package {
            gtkmm2 = pkgsGtk2.gtkmm2;
            glibmm = pkgsGtk2.glibmm;
            cairomm = pkgsGtk2.cairomm;
            pangomm = pkgsGtk2.pangomm;
            libsigcxx = pkgsGtk2.libsigcxx;
          };
        in
        {
          baidunetdisk = package;
          default = package;
        }
      );
    };
}
