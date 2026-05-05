{ ... }:

{
  flake.modules.homeManager.linphone =
    {
      secrets,
      pkgs,
      lib,
      ...
    }:
    {
      home.packages = [ pkgs.linphone ];

      home.activation.linphonerc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        config_dir="$HOME/.config/linphone"
        config_file="$config_dir/linphonerc"
        template=${
          pkgs.writeText "linphonerc" lib.generators.toINI { } {
            "proxy_0" = {
              reg_identity = "sip:${secrets.voipUsername}@sip1.superloop.com";
              reg_proxy = "<sip:sip1.superloop.com;transport=udp>";
              reg_expires = 3600;
              reg_sendregister = 1;
              realm = "sip1.superloop.com";
            };

            "auth_info_0" = {
              username = secrets.voipUsername;
              passwd = secrets.voipPassword;
              domain = "sip1.superloop.com";
              realm = "sip1.superloop.com";
              algorithm = "MD5";
            };

            sip = {
              media_encryption = "none";
              verify_server_certs = 0;
              verify_server_cn = 0;
            };

            "audio_codec_0" = {
              mime = "PCMA";
              rate = 8000;
              channels = 1;
              enabled = 1;
            };

            "audio_codec_1" = {
              mime = "PCMU";
              rate = 8000;
              channels = 1;
              enabled = 1;
            };

            "audio_codec_2" = {
              mime = "opus";
              rate = 48000;
              channels = 2;
              enabled = 0;
            };

            "audio_codec_3" = {
              mime = "speex";
              rate = 16000;
              channels = 1;
              enabled = 0;
            };

            "audio_codec_4" = {
              mime = "speex";
              rate = 8000;
              channels = 1;
              enabled = 0;
            };

            "audio_codec_5" = {
              mime = "GSM";
              rate = 8000;
              channels = 1;
              enabled = 0;
            };

            "audio_codec_6" = {
              mime = "G722";
              rate = 8000;
              channels = 1;
              enabled = 0;
            };

            ui = {
              rc_version = 7;
            };
          }
        }

        # Preserve existing uuid if present
        uuid=""
        if [ -f "$config_file" ]; then
          uuid=$(${pkgs.gnugrep}/bin/grep -oP '^uuid=\K.+' "$config_file" || true)
        fi

        $DRY_RUN_CMD mkdir -p "$config_dir"
        $DRY_RUN_CMD cp "$template" "$config_file"
        $DRY_RUN_CMD chmod 600 "$config_file"

        if [ -n "$uuid" ]; then
          $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i "s/^uuid=.*/uuid=$uuid/" "$config_file"
        fi
      '';
    };
}
