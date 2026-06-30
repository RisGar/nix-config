{
  config,
  pkgs,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];
  # nix build .#nixosConfigurations.study-usb.config.system.build.isoImage

  # Disable installer configuration clones and desktop installer behavior
  installer.cloneConfig = false;

  nixpkgs.hostPlatform = "x86_64-linux";

  # X11 Windowing System and AwesomeWM
  services.xserver = {
    enable = true;
    windowManager.awesome.enable = true;
    displayManager.lightdm.enable = true;
  };

  # Provide the custom awesome config
  environment.etc."xdg/awesome/rc.lua".source = ./rc.lua;

  # Sudoless user
  users.users.guest = {
    isNormalUser = true;
    description = "guest account";
    extraGroups = [
      "networkmanager"
      "video"
      "audio"
    ];

    # Leaving out 'password', 'hashedPassword', and 'initialPassword'
    # creates a passwordless account that blocks traditional password logins.
  };

  services.displayManager.autoLogin = {
    enable = true;
    user = "guest";
  };

  # Disable networking to ensure a distraction-free environment
  networking.networkmanager.enable = lib.mkForce false;
  networking.wireless.enable = lib.mkForce false;
  networking.useDHCP = lib.mkForce false;

  # Specific software suite requested
  environment.systemPackages = with pkgs; [
    apostrophe # Text editor / Markdown notes
    papers # PDF viewer
    totem # GNOME video player for lectures
    gnome-calculator # GNOME calculator
  ];

  # The NixOS installation-cd-minimal.nix module already provides:
  # - A bootable ISO configuration
  # - A default "nixos" user with no password
  # - Required hardware support
}
