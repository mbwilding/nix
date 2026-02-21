{ ... }:

{
  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
      silent = false;
      config = {
        global = {
          warn_timeout = "2m";
          hide_env_diff = true;
        };
      };
    };
  };
}
