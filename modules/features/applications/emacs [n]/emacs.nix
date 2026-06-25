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
          (tool-bar-mode 0)
          (menu-bar-mode 0)
          (scroll-bar-mode 0)
          (global-display-line-numbers-mode)
          (display-line-numbers-type 'relative)

          (modify-all-frames-parameters
           '((border-width . 0)
             (internal-border-width . 0)))

          ;; Set up package.el to work with MELPA
          (require 'package)
          (add-to-list 'package-archives
                       '("melpa" . "https://melpa.org/packages/"))
          (package-initialize)
          (package-refresh-contents)

          ;; Download Evil
          (unless (package-installed-p 'evil)
            (package-install 'evil))

          ;; Enable Evil
          (require 'evil)
          (evil-mode 1)
        '';
      };
    };
}
