{ pkgs, ... }:

{
  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
        fail_timeout = 2000;
      };

      animations = {
        enabled = true;
        bezier = "linear, 1, 1, 0, 0";
        animation = "fade, 1, 2.0, linear";
      };

      background = [
        {
          monitor = "";
          color = "rgba(000000ff)";
        }
      ];

      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgba(f66e25ff)";
          font_size = 96;
          font_family = "Noto Sans CJK JP";
          position = "0, 150";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "360, 54";
          position = "0, 0";
          halign = "center";
          valign = "center";
          outline_thickness = 2;
          rounding = 0;
          inner_color = "rgba(000000ff)";
          outer_color = "rgba(f66e25ff)";
          font_color = "rgba(f66e25ff)";
          check_color = "rgba(f66e25ff)";
          fail_color = "rgba(f66e25ff)";
          dots_size = 0.22;
          dots_spacing = 0.18;
          dots_center = true;
          fade_on_empty = false;
          placeholder_text = "<b>LOCKED</b>";
          fail_text = "<b>REFUSED ($ATTEMPTS)</b>";
          font_family = "Noto Sans CJK JP";
        }
      ];
    };
  };

  systemd.user.services.swayidle = {
    Unit = {
      Description = "Idle manager for niri sessions";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.writeShellScript "niri-swayidle" ''
        exec ${pkgs.swayidle}/bin/swayidle -w \
          timeout 600 '${pkgs.hyprlock}/bin/hyprlock' \
          timeout 900 '${pkgs.niri}/bin/niri msg action power-off-monitors' \
            resume '${pkgs.niri}/bin/niri msg action power-on-monitors' \
          before-sleep '${pkgs.hyprlock}/bin/hyprlock'
      ''}";
      Restart = "on-failure";
      RestartSec = 5;
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.packages = with pkgs; [
    # Idle manager used by the niri desktop session.
    swayidle
  ];
}
