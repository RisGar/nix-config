{
  config,
  lib,
  pkgs,
  ...
}:
let
  model = "qwen3.5:4b";
  storageRoot = "/mnt/external/papra";
in
{
  services.samba = {
    enable = true;
    usershares.enable = true;
    openFirewall = true;
    settings = {
      "tm_share" = {
        "path" = "/mnt/external/TimeMachine";
        "valid users" = "rishab";
        "public" = "no";
        "writeable" = "yes";
        "fruit:aapl" = "yes";
        "fruit:time machine" = "yes";
        "fruit:time machine max size" = "1T";
        "vfs objects" = "catia fruit streams_xattr";
      };
    };
  };

  # seed the passdb from sops on every activation as there is no declarative option in `services.samba`
  system.activationScripts.init_smbpasswd.text = ''
    password="$(cat ${config.sops.secrets.user-rishab.path})"
    printf '%s\n' "$password" "$password" | ${lib.getExe' pkgs.samba "smbpasswd"} -sa rishab
  '';

  services.ollama = {
    enable = true;
    syncModels = true; # declarative models
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
      SERVER_HOSTNAME = "127.0.0.1";

      AUTH_IP_ADDRESS_HEADERS = "cf-connecting-ip,x-forwarded-for";

      AUTH_PROVIDERS_EMAIL_IS_ENABLED = false;
      AUTH_IS_PASSWORD_RESET_ENABLED = false;

      DOCUMENTS_CONTENT_EXTRACTION_ENABLED = true;
      CONTENT_EXTRACTION_STRATEGY = "internal"; # bundled tesseract

      DOCUMENT_STORAGE_DRIVER = "filesystem";
      DOCUMENT_STORAGE_FILESYSTEM_ROOT = "${storageRoot}/local-documents";

      AI_IS_ENABLED = true;
      AI_CREDITS_IS_ENABLED = false; # no metering for self-hosting
      OLLAMA_BASE_URL = "http://${config.services.ollama.host}:${toString config.services.ollama.port}/v1";
      AI_DEFAULT_MODEL = "ollama://${model}";
      AUTO_TAGGING_ENABLED = true;
      AUTO_TAGGING_MODEL = "ollama://${model}";

    };
  };

  systemd.services.papra.unitConfig.RequiresMountsFor = [ storageRoot ];
}
