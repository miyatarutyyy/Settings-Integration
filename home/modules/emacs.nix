{ pkgs, ... }:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;

    extraPackages =
      epkgs: with epkgs; [
        cape
        consult
        corfu
        marginalia
        nix-ts-mode
        orderless
        treesit-grammars.with-all-grammars
        vertico
        vterm
        yasnippet
      ];
  };

  home.packages = with pkgs; [
    arduino-cli
    arduino-language-server
  ];

  home.file = {
    ".emacs.d/init.org".source = ../emacs/init.org;
    ".emacs.d/init.el".source = ../emacs/init.el;
    ".emacs.d/custom.el".source = ../emacs/custom.el;
    ".emacs.d/themes/miyatarutyyy-interface-theme.el".source =
      ../emacs/themes/miyatarutyyy-interface-theme.el;
  };
}
