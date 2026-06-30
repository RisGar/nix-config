{ config, ... }:
{
  apps."ollama" = {
    port = 11434;
    hostname = null; # Don't publish ollama
  };
  services.ollama = {
    enable = true;
    port = config.apps."ollama".port;
    syncModels = true; # Declarative models
    loadModels = [
      "qwen3.5:9b"
    ];
  };
}
