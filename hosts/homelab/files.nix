{ config, pkgs, ... }:
let
  model = "qwen3.5:4b";
  storageRoot = "/mnt/external/papra";
in
{
  services.ollama = {
    enable = true;
    syncModels = true; # Declarative models
    loadModels = [ model ];
  };

  apps."files" = {
    port = config.services.papra.environment.PORT;
  };

  sops.templates."papra" = {
    content = ''
      AUTH_SECRET=${config.sops.placeholder."papra/auth-secret"}
      AUTH_PROVIDERS_CUSTOMS=${
        builtins.toJSON [
          {
            providerId = "pocket-id";
            providerName = "Pocket ID";
            discoveryUrl = "https://${config.apps."auth".hostname}/.well-known/openid-configuration";
            clientId = "6c78ee8b-14c3-4fc5-b586-28d361e66abd";
            clientSecret = config.sops.placeholder."papra/oidc-client-secret";
            scopes = [
              "openid"
              "email"
              "profile"
              "groups"
            ];
            pkce = true;
          }
        ]
      }
    '';
  };

  services.papra = {
    enable = true;
    environmentFiles = [ config.sops.templates."papra".path ];

    environment = {
      APP_BASE_URL = "https://${config.apps."files".hostname}";

      # Reached through the cloudflared tunnel and Caddy, both of which set the
      # client IP headers; used for rate limiting.
      AUTH_IP_ADDRESS_HEADERS = "cf-connecting-ip,x-forwarded-for";

      AUTH_PROVIDERS_EMAIL_IS_ENABLED = false;
      AUTH_IS_PASSWORD_RESET_ENABLED = false;

      DOCUMENTS_CONTENT_EXTRACTION_ENABLED = true;
      CONTENT_EXTRACTION_STRATEGY = "internal"; # bundled tesseract

      # Documents/ingestion on /mnt/external, database in /var/lib/papra.
      DOCUMENT_STORAGE_DRIVER = "filesystem";
      DOCUMENT_STORAGE_FILESYSTEM_ROOT = "${storageRoot}/local-documents";
      INGESTION_FOLDER_ROOT_PATH = "${storageRoot}/ingestion";
      # Set INGESTION_FOLDER_IS_ENABLED = true to auto-import files dropped
      # into <storageRoot>/ingestion/<organization id>.

      AI_IS_ENABLED = true;
      AI_CREDITS_IS_ENABLED = false; # no metering for self-hosting
      OLLAMA_BASE_URL = "http://${config.services.ollama.host}:${toString config.services.ollama.port}/v1";
      AI_DEFAULT_MODEL = "ollama://${model}";
      AUTO_TAGGING_ENABLED = true;
      AUTO_TAGGING_MODEL = "ollama://${model}";
    };
  };

  # Don't start before the documents disk is mounted.
  systemd.services.papra.unitConfig.RequiresMountsFor = [ storageRoot ];

  systemd.services.papra-dirs = {
    description = "Create Papra documents and ingestion directories";
    requiredBy = [ "papra.service" ];
    unitConfig.RequiresMountsFor = [ storageRoot ];
    script = ''
      ${pkgs.coreutils}/bin/install -d -m 0700 -o papra -g papra ${storageRoot}/local-documents
      ${pkgs.coreutils}/bin/install -d -m 0770 -o papra -g papra ${storageRoot}/ingestion
    '';
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
  };
}
