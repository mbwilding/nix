let
  sudoUser = builtins.getEnv "SUDO_USER";
in
if sudoUser != "" then "/home/${sudoUser}" else builtins.getEnv "HOME"
