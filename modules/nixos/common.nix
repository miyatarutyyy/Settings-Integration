{
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./desktop.nix
    ./host-services.nix
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.config.allowUnfree = true;

  hardware.enableRedistributableFirmware = lib.mkDefault true;

  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "dialout"
      "docker"
      "incus-admin"
    ];
    shell = pkgs.bashInteractive;
  };

  programs.bash.completion.enable = true;
  programs.nix-ld.enable = true;

  home-manager.backupFileExtension = "hm-backup";

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
    wget
  ];

  networking.useDHCP = lib.mkDefault true;
  networking.wireless.iwd = {
    enable = lib.mkDefault true;
    settings.Settings.AutoConnect = true;
  };

  services.openssh.enable = lib.mkDefault true;
}
