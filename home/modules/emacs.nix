{ pkgs, ... }:

let
  emacsPackage = pkgs.emacs-pgtk;
in

{
  programs.emacs = {
    enable = true;
    package = emacsPackage;
  };

  services.emacs = {
    enable = true;
    package = emacsPackage;
    client.enable = true;
  };

  home.packages = with pkgs; [
    arduino-cli
    arduino-language-server
    clang-tools
  ];

  home.file = {
    ".emacs.d/init.org".source = ../emacs/init.org;
    ".emacs.d/init.el".source = ../emacs/init.el;
    ".emacs.d/custom.el".source = ../emacs/custom.el;
    ".emacs.d/themes/miyatarutyyy-interface-theme.el".source =
      ../emacs/themes/miyatarutyyy-interface-theme.el;
  };
}
