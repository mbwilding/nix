{ pkgs, config, ... }:

let
  # Pixel formats that work with the Elgato Cam Link 4K, by resolution.
  # Varies based on what the connected camera negotiates (e.g. Sony A6500).
  #   1080p -> yuyv422
  #   4K    -> nv12
  # Output is always yuv420p (broadly supported by Chrome, Zoom, etc.)

  setupScript = pkgs.writeShellScript "elgato-loopback-setup" ''
    set -euo pipefail

    V4L2CTL="${pkgs.v4l-utils}/bin/v4l2-ctl"
    FFMPEG="${pkgs.ffmpeg}/bin/ffmpeg"

    # --- find devices by name ---
    DEVICES=$("$V4L2CTL" --list-devices)

    find_device() {
      local name="$1"
      # The device path follows the block starting with $name
      echo "$DEVICES" | awk -v name="$name" '
        $0 ~ name { found=1; next }
        found && /^\t/ { gsub(/\t/, ""); print; exit }
      '
    }

    ELGATO=$(find_device "Cam Link 4K: Cam Link 4K")
    DUMMY=$(find_device "Dummy video device (0x0000)")

    if [ -z "$ELGATO" ]; then
      echo "ERROR: Elgato Cam Link 4K not found" >&2
      exit 1
    fi
    if [ -z "$DUMMY" ]; then
      echo "ERROR: Dummy v4l2loopback device not found" >&2
      exit 1
    fi

    echo "Elgato device: $ELGATO"
    echo "Dummy device:  $DUMMY"

    # --- query resolution and fps from the active format ---
    FORMATS=$("$V4L2CTL" --list-formats-ext -d "$ELGATO")

    WIDTH=$(echo "$FORMATS" | awk '/Size: Discrete/ { match($0, /([0-9]+)x([0-9]+)/, a); print a[1]; exit }')
    HEIGHT=$(echo "$FORMATS" | awk '/Size: Discrete/ { match($0, /([0-9]+)x([0-9]+)/, a); print a[2]; exit }')
    FPS=$(echo "$FORMATS" | awk '/Interval: Discrete/ { match($0, /\(([0-9.]+) fps\)/, a); print a[1]; exit }')

    echo "Detected: ''${WIDTH}x''${HEIGHT} @ ''${FPS} fps"

    # --- select input pixel format based on resolution ---
    case "''${WIDTH}x''${HEIGHT}" in
      1920x1080) PIX_FMT_IN="yuyv422" ;;
      3840x2160) PIX_FMT_IN="nv12" ;;
      *)
        echo "WARNING: Unknown resolution ''${WIDTH}x''${HEIGHT}, defaulting to yuyv422" >&2
        PIX_FMT_IN="yuyv422"
        ;;
    esac

    exec "$FFMPEG" \
      -f v4l2 \
      -framerate "$FPS" \
      -pix_fmt "$PIX_FMT_IN" \
      -video_size "''${WIDTH}x''${HEIGHT}" \
      -i "$ELGATO" \
      -f v4l2 \
      -vcodec rawvideo \
      -pix_fmt yuv420p \
      "$DUMMY"
  '';
in
{
  # v4l2loopback: virtual camera device for the forwarded Elgato output
  boot.kernelModules = [ "v4l2loopback" ];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # video_nr=10  -> /dev/video10
  # card_label   -> display name in apps (Zoom, Chrome, etc.)
  # exclusive_caps=1 -> device only appears in apps when actually streaming
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="Elgato Cam" exclusive_caps=1
  '';

  environment.systemPackages = with pkgs; [
    v4l-utils
    ffmpeg
  ];

  systemd.services.elgato-loopback = {
    description = "Elgato Cam Link 4K -> v4l2loopback forwarding via ffmpeg";
    # Start after the multi-user target so USB devices are enumerated
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      ExecStart = setupScript;
      # Restart automatically if ffmpeg exits (camera unplugged, etc.)
      Restart = "on-failure";
      RestartSec = "10s";
      # Run as root so it can open /dev/video* without udev rules
      # (alternatively add the user to the 'video' group, which anon already is)
      User = "root";
    };
  };
}
