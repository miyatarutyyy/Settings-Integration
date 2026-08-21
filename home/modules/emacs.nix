{ pkgs, ... }:

let
  emacsPackage = pkgs.emacs-pgtk;
  typeScriptTreeSitterGrammars = pkgs.tree-sitter.withPlugins (
    grammars: with grammars; [
      tree-sitter-typescript
      tree-sitter-tsx
    ]
  );
  emacsTreeSitterGrammars = pkgs.runCommand "emacs-treesit-grammars" { } ''
    mkdir -p "$out/lib"
    ln -s ${typeScriptTreeSitterGrammars}/typescript.so "$out/lib/libtree-sitter-typescript.so"
    ln -s ${typeScriptTreeSitterGrammars}/tsx.so "$out/lib/libtree-sitter-tsx.so"
  '';
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

  systemd.user.services.emacs.Service.Environment = [
    "GTK_IM_MODULE=fcitx"
    "QT_IM_MODULE=fcitx"
    "XMODIFIERS=@im=fcitx"
    "INPUT_METHOD=fcitx"
    "SDL_IM_MODULE=fcitx"
  ];

  home.packages = with pkgs; [
    arduino-cli
    arduino-language-server
    clang-tools
    emacsTreeSitterGrammars
    typescript
    typescript-language-server
  ];

  home.file = {
    ".emacs.d/init.org".source = ../emacs/init.org;
    ".emacs.d/init.el".source = ../emacs/init.el;
    ".emacs.d/custom.el".source = ../emacs/custom.el;
    ".emacs.d/themes/miyatarutyyy-interface-theme.el".source =
      ../emacs/themes/miyatarutyyy-interface-theme.el;
  };
}
