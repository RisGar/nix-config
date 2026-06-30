# Study USB

Minimal NixOS system

## Build instructions

```bash
NIX_SSHOPTS="-p 60204" nix build .#nixosConfigurations.study-usb.config.system.build.isoImage --store "ssh-ng://root@psa.in.tum.de"
NIX_SSHOPTS="-p 60204" nix copy --from "ssh-ng://root@psa.in.tum.de" .#nixosConfigurations.study-usb.config.system.build.isoImage
nix build .#nixosConfigurations.study-usb.config.system.build.isoImage
```
