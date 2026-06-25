{ ... }:

{
  flake.modules.homeManager.emacs =
    { ... }:

    {
      # services.emacs = {
      #   enable = false;
      #   startWithUserSession = true;
      #   defaultEditor = false;
      #   extraOptions = null;
      # };

      programs.emacs = {
        enable = true;
        extraConfig = ''
          (menu-bar-mode -1)
          (tool-bar-mode -1)
        '';
      };
    };
}
