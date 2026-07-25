{
  config,
  pkgs,
  ...
}:

{
  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings = {
      default_session = {
        user = "greeter";
        command = ''
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --time \
            --asterisks \
            --remember \
            --user-menu \
            --user-menu-min-uid 1000 \
            --cmd ${config.programs.niri.package}/bin/niri-session
        '';
      };
    };
  };
}
