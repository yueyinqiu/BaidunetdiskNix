{
  description = "Baidu Netdisk (百度网盘) — Nix flake for the official Linux client";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Only used to obtain the gtk2/gtkmm2 stack, whose ABI the bundled
    # `libbrowserengine.so` links against. These were removed from recent
    # nixpkgs, so keep them on this older pin.
    nixpkgs-old.url = "github:NixOS/nixpkgs/f13ff45afd1bb73e640eaa08a7066dbed07e3238";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-old,
    }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgsOld = import nixpkgs-old {
            inherit system;
            config.allowUnfree = true;
          };
          package = pkgs.callPackage ./package {
            inherit (pkgsOld)
              gtkmm2
              gtk2
              glibmm
              atkmm
              cairomm
              pangomm
              libsigcxx
              ;
          };
        in
        {
          baidunetdisk = package;
          default = package;
        }
      );
    };
}
