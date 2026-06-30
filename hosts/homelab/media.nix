{ ... }: {
  services.jellyfin = {
    enable = true;
    forceEncodingConfig = true;
  };
  apps."media" = {
    port = 8096;
  };
}
