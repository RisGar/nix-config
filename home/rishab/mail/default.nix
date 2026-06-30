{ pkgs, lib, ... }: {
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
      withExternalGnupg = true;
      settings = {
        "mail.server.default.check_all_folders_for_new" = true; # For mails that get put directly into folders through sieve
      };
    };
  };

  home.activation = {
    symlinkGpgme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p /usr/local/lib
      run ln -sf ${pkgs.gpgme}/lib/libgpgme.dylib /usr/local/lib/libgpgme.dylib
    '';
  };
}
