{ pkgs, ... }:

{
  # niri itself, greetd, portals, and PAM are system-level concerns.
  # This module keeps the user-facing tools and dotfiles together.

  programs.alacritty = {
    enable = true;

    settings = {
      window.padding = {
        x = 8;
        y = 8;
      };

      font = {
        normal.family = "HackGen Console NF";
        size = 11;
      };

      colors.primary = {
        background = "#101010";
        foreground = "#eeeeee";
      };
    };
  };

  programs.rofi = {
    enable = true;
    terminal = "alacritty";

    extraConfig = {
      modi = "drun,run,ssh";
      show-icons = true;
    };
  };

  programs.hyprlock = {
    enable = true;

    settings = {
      general = {
        hide_cursor = true;
        ignore_empty_input = true;
      };

      background = [
        {
          monitor = "";
          color = "rgba(10, 10, 10, 1.0)";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "240, 48";
          position = "0, -40";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(238, 238, 238)";
          inner_color = "rgb(20, 20, 20)";
          outer_color = "rgb(246, 110, 37)";
          outline_thickness = 2;
          placeholder_text = ''<span foreground="##eeeeee">Password</span>'';
        }
      ];
    };
  };

  programs.waybar = {
    enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 30;

      modules-left = [ ];
      modules-center = [ "clock" ];
      modules-right = [
        "custom/ime"
        "memory"
        "battery"
        "network"
        "pulseaudio"
      ];

      clock = {
        format = "[ Asia / Tokyo | {:%H:%M} ]";
        tooltip-format = "{:%Y-%m-%d %A}";
      };

      "custom/ime" = {
        exec = "${pkgs.writeShellScript "waybar-ime-status" ''
          name="$(${pkgs.fcitx5}/bin/fcitx5-remote -n 2>/dev/null || true)"

          case "$name" in
            skk)
              text="SKK"
              class="ime-skk"
              ;;
            keyboard-us|"")
              text="DIRECT"
              class="ime-direct"
              ;;
            *)
              text="$name"
              class="ime-other"
              ;;
          esac

          ${pkgs.jq}/bin/jq -cn \
            --arg text "$text" \
            --arg class "$class" \
            '{text: $text, class: $class}'
        ''}";
        interval = 1;
        return-type = "json";
        format = "[ IME : {} ]";
      };

      memory = {
        format = "[ MEM {percentage}% ]";
      };

      battery = {
        format = "[ BAT {capacity}% ]";
        format-charging = "[ CHR {capacity}% ]";
        format-plugged = "[ AC {capacity}% ]";
      };

      network = {
        format-wifi = "[ NET {signalStrength}% ]";
        format-ethernet = "[ ETH ]";
        format-disconnected = "[ NET off ]";
      };

      pulseaudio = {
        format = "[ VOL {volume}% ]";
        format-muted = "[ MUTED ]";
        on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      };
    };

    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "HackGen Console NF", "Noto Sans CJK JP", sans-serif;
        font-size: 12px;
      }

      window#waybar {
        background: #101010;
        color: #eeeeee;
      }

      #clock,
      #custom-ime,
      #memory,
      #battery,
      #network,
      #pulseaudio {
        padding: 0 10px;
      }

      #clock,
      #custom-ime.ime-skk {
        color: #f66e25;
      }

      #custom-ime.ime-direct {
        color: #eeeeee;
      }

      #battery.warning,
      #battery.critical,
      #network.disconnected,
      #pulseaudio.muted {
        color: #ff5f57;
      }
    '';
  };

  home.packages = with pkgs; [
    # Clipboard utilities for Wayland sessions.
    wl-clipboard
    # Screenshot region selector used by Wayland screenshot workflows.
    slurp
    # Screenshot capture tool for Wayland.
    grim
    # Lightweight Wayland screen recorder.
    wf-recorder
    # Desktop notification command-line client.
    libnotify
    # XWayland bridge for niri sessions.
    xwayland-satellite
  ];
}
