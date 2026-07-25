{ pkgs, ... }:

{
  # Project-local environments are provided by each repository's flake.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    # Nix configuration tooling.
    # Official formatter for Nix code.
    nixfmt-rfc-style
    # Nix language server for editors.
    nixd
    # Linter for Nix expressions.
    statix
    # Detects unused Nix code.
    deadnix
    # Readable monitor for Nix build output.
    nix-output-monitor

    # Shell script tooling.
    # Shell script linter.
    shellcheck
    # Shell script formatter.
    shfmt

    # GitHub, CI, and repository inspection.
    # GitHub Actions workflow linter.
    actionlint
    # Secret scanner for Git repositories and working trees.
    gitleaks
    # Graph rendering tools such as dot.
    graphviz

    # Everyday command-line utilities.
    # cat replacement with syntax highlighting and paging.
    bat
    # Interactive process and resource monitor.
    btop
    # Disk usage and mount overview.
    duf
    # Disk usage analyzer.
    du-dust
    # ls replacement with Git-aware display.
    eza
    # Local system information summary.
    fastfetch
    # find replacement for fast file lookup.
    fd
    # Detects file types.
    file
    # JSON query and transformation tool.
    jq
    # Text pager used by many command-line tools.
    less
    # grep replacement for fast source search.
    ripgrep
    # Directory tree viewer.
    tree
    # Shows which executable would be run.
    which

    # File transfer and archive utilities.
    # File synchronization and migration utility.
    rsync
    # Zip archive creator.
    zip
    # Zip archive extractor.
    unzip
  ];
}
