{ config, ... }:
{
  ports.ollama = 11434;
  services.ollama = {
    enable = true;
    port = config.ports.ollama;
    syncModels = true; # Declarative models
    loadModels = [
      "qwen3.5:9b"
    ];
  };
}
