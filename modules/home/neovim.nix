{ lib, pkgs, ... }:

{
  home = {
    activation.cloneNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" "everything" ] ''
      if [ ! -d ~/.config/nvim ]; then
        GIT_SSH=${pkgs.openssh}/bin/ssh ${pkgs.git}/bin/git clone git@github.com:mbwilding/nvim ~/.config/nvim
      fi
    '';
  };
}
