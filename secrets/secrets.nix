let
  # User / Admin Keys (can decrypt everything to edit)
  rishabs-macbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJWmextJLZ2oObSyUPW0pqUq9nnSWuZkieDB+CaY9hLy";

  # Host Keys (can decrypt only what they need)
  rishabs-homelab = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+74XpLMdeUesLv6mGZIdqItpITQexLj9IVdeuzAnV5";
  # vps = "ssh-ed25519 ..."; # TODO: Add your VPS public key here

  # Groups
  homelab_keys = [
    rishabs-macbook
    rishabs-homelab
  ];
in
{
  # Homelab only
  "anilist-mal-sync.age".publicKeys = homelab_keys;
  "context7.age".publicKeys = homelab_keys;
  "nordvpn.age".publicKeys = homelab_keys;
  "openrouter.age".publicKeys = homelab_keys;
  "pocket-id.age".publicKeys = homelab_keys;
  "tandoor.age".publicKeys = homelab_keys;
  "tavily.age".publicKeys = homelab_keys;
  "user-rishab.age".publicKeys = homelab_keys;
  "user-root.age".publicKeys = homelab_keys;
  "wg-private.age".publicKeys = homelab_keys;
}
