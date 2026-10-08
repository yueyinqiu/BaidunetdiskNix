# BaidunetdiskNix

Nix packaging for [Baidu Netdisk](https://pan.baidu.com) — the official Linux desktop client for Baidu Netdisk (百度网盘).

## Adding as a flake input

```nix
{
  inputs = {
    baidunetdisk.url = "github:yueyinqiu/BaidunetdiskNix";
  };
}
```

## Package

The package is `unfree` and only available on `x86_64-linux`, so `allowUnfree` must be enabled:

```nix
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [ baidunetdisk.packages.x86_64-linux.default ];
}
```

Or run it directly:

```console
$ nix run github:yueyinqiu/baidunetdisk-nix
```

## Notes

- The app bundles its own Electron, which keeps its original `/lib64/...` interpreter and does not tolerate ELF patching. It is therefore run inside an FHS environment (`buildFHSEnv`) rather than being patched.
- The gtk2/gtkmm2 stack required by the bundled `libbrowserengine.so` is taken from an older nixpkgs pin, as those packages have been removed from recent nixpkgs.

---

All documentation and `description` fields in this repository are AI-generated.
