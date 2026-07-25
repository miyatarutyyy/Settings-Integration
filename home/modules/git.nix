{ ... }:

{
  programs.git = {
    enable = true;

    # Git identity and signing keys are intentionally left to a later
    # secret-aware step instead of guessing name, email, or GPG key IDs.
    extraConfig = {
      init.defaultBranch = "master";
      pull.rebase = false;
      fetch.prune = true;
      push.autoSetupRemote = true;
    };
  };

  programs.gh = {
    enable = true;

    settings = {
      git_protocol = "ssh";
      prompt = "enabled";

      aliases = {
        co = "pr checkout";
      };
    };
  };

  programs.ssh = {
    enable = true;

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
        extraOptions.AddKeysToAgent = "yes";
      };

      "github-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
        extraOptions.AddKeysToAgent = "yes";
      };

      "github-private" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github";
        identitiesOnly = true;
        extraOptions.AddKeysToAgent = "yes";
      };

      "github-iniad" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github_iniad";
        identitiesOnly = true;
        extraOptions.AddKeysToAgent = "yes";
      };

      "github.com-iniad" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_github_iniad";
        identitiesOnly = true;
        extraOptions.AddKeysToAgent = "yes";
      };
    };
  };
}
