{ ... }:

{
  programs.git = {
    enable = true;

    # Git identity and signing keys are intentionally left to a later
    # secret-aware step instead of guessing name, email, or GPG key IDs.
    settings = {
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
    enableDefaultConfig = false;

    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      "github-personal" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      "github-private" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      "github-iniad" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github_iniad";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      "github.com-iniad" = {
        HostName = "github.com";
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_github_iniad";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };
    };
  };
}
