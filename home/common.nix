{
  ...
}:

{
  imports = [
    ./modules/desktop.nix
    ./modules/development.nix
    ./modules/git.nix
    ./modules/shell.nix
  ];

  programs.home-manager.enable = true;
}
