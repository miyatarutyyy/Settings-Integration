{ pkgs, ... }:

{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    fd
    gh
    jq
    ripgrep
  ];
}
