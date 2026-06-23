{ ... }:

{
  # Disable dconf on WSL (no D-Bus / GNOME session)
  dconf.enable = false;

  programs.fish.interactiveShellInit = ''
    # Windows paths (WSL)
    set -Ux fish_user_paths \
        /mnt/c/Windows \
        /mnt/c/Windows/System32 \
        /mnt/c/Program\ Files/PowerShell/7 \
        /mnt/c/Windows/System32/WindowsPowerShell/v1.0 \
        $fish_user_paths
  '';
}
