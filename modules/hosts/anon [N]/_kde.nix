{ pkgs, ... }:

let
  kscreen-doctor = "${pkgs.kdePackages.libkscreen}/bin/kscreen-doctor";
in
{
  # Apply kscreen monitor layout on login.
  # Layout (vertical | horizontal | vertical):
  #   - LG Ultrawide 2560x1080 (DP-1): rotated CW (right), positioned left of TV at 0,0
  #   - LG TV 3840x2160 (HDMI-A-1): normal, at 1080,0
  #   - Dell AW3418DW 3440x1440 (DP-2): rotated CCW (left), at 4920,0
  # kscreen rotation values: 1=normal, 2=left/CCW, 4=inverted, 8=right/CW
  systemd.user.services.kscreen-layout = {
    Unit = {
      Description = "Apply kscreen monitor layout";
      After = [ "plasma-core.target" ];
      PartOf = [ "plasma-core.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "kscreen-layout" ''
        ${kscreen-doctor} \
          output.DP-1.position.0,0 \
          output.DP-1.rotation.right \
          output.HDMI-A-1.position.1080,0 \
          output.HDMI-A-1.rotation.none \
          output.DP-2.position.4920,-640 \
          output.DP-2.rotation.left
      '';
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "plasma-core.target" ];
  };
}
