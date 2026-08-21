{ pkgs, ... }:

{
  home.packages = with pkgs; [
    floorp-bin
    discord
    mpv
    pwvucontrol
    element-desktop
  ];
}
