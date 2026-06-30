# Agent Instructions

## Rebuilds are the user's job — never self-apply

- **Do not rebuild or activate any host.** Make the configuration change, then stop and tell the user to run the rebuild; wait for them to do it.
- **Forbidden on every host** (`Rishabs-MacBook-Pro`, `Rishabs-Homelab`, `study-usb`): `darwin-rebuild switch`/`activate`, `nixos-rebuild switch`/`boot`/`test`/`dry-activate`, or any other command that changes the running system.
- **Allowed for verification only** (never activation): `nix flake check`, `nix eval`, and build-only commands such as `darwin-rebuild build --flake .#Rishabs-MacBook-Pro` or `nixos-rebuild build --flake .#Rishabs-Homelab`. Report the result; do not apply it.
- **Hand off with the exact command**, e.g. `sudo -i darwin-rebuild switch --flake .#Rishabs-MacBook-Pro`.

## Repository rules

- When testing or debugging something in the `hosts/homelab` folder, always SSH to the host "homelab".
- **Declarative Homebrew**: Homebrew on macOS is managed declaratively via `nix-homebrew` with `mutableTaps = false`. **Never run `brew install` or `brew tap` imperatively**; always add packages/taps directly to the Nix configuration.
- **Secrets**: Secrets are managed by `sops-nix` (`.sops.yaml`). Never store plain-text secrets in the repository.
- **Available Hosts**:
  - macOS: `Rishabs-MacBook-Pro` (`hosts/macbook`)
  - NixOS: `Rishabs-Homelab` (`hosts/homelab`)
  - NixOS USB: `study-usb` (`hosts/study-usb`)
