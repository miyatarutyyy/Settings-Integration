{
  ...
}:

{
  imports = [
    ./modules/development.nix
    ./modules/shell.nix
  ];

  programs.home-manager.enable = true;
}
