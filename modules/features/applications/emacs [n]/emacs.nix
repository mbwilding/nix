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
          (setq inhibit-startup-screen t)

          (tool-bar-mode 0)
          (menu-bar-mode 0)
          (scroll-bar-mode 0)

          (modify-all-frames-parameters
           '((border-width . 0)
             (internal-border-width . 0)))

          (column-number-mode 1)
        '';
      };
    };
}
