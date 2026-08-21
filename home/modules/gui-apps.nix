{ pkgs, ... }:

let
  elementDesktop = pkgs.symlinkJoin {
    name = "element-desktop";
    paths = [ pkgs.element-desktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      rm "$out/bin/element-desktop"
      makeWrapper ${pkgs.element-desktop}/bin/element-desktop "$out/bin/element-desktop" \
        --add-flags "--password-store=gnome-libsecret"

      rm "$out/share/applications/element-desktop.desktop"
      install -Dm644 \
        ${pkgs.element-desktop}/share/applications/element-desktop.desktop \
        "$out/share/applications/element-desktop.desktop"
      substituteInPlace "$out/share/applications/element-desktop.desktop" \
        --replace-fail "Exec=element-desktop %u" "Exec=$out/bin/element-desktop %u"
    '';
  };
in

{
  home.packages = with pkgs; [
    floorp-bin
    discord
    mpv
    pwvucontrol
    elementDesktop
  ];
}
