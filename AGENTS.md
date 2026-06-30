# Agent Instructions

- When testing or debugging something in the `hosts/homelab` folder, always SSH to the host "homelab".
- **macOS Rebuilds**: Apply macOS system configuration changes using `sudo -i darwin-rebuild switch --flake .#Rishabs-MacBook-Pro` (or `build` to test).
- **Declarative Homebrew**: Homebrew on macOS is managed declaratively via `nix-homebrew` with `mutableTaps = false`. **Never run `brew install` or `brew tap` imperatively**; always add packages/taps directly to the Nix configuration.
- **Secrets**: Secrets are managed by `sops-nix` (`.sops.yaml`). Never store plain-text secrets in the repository.
- **Available Hosts**:
  - macOS: `Rishabs-MacBook-Pro` (`hosts/macbook`)
  - NixOS: `Rishabs-Homelab` (`hosts/homelab`)
  - NixOS USB: `study-usb` (`hosts/study-usb`)
