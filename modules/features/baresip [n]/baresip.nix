{ ... }:

{
  flake.modules.homeManager.baresip =
    { secrets, pkgs, ... }:

    {
      home.packages = [ pkgs.baresip ];

      # Account format per upstream docs:
      # <sip:user@domain>;auth_pass=password
      home.file.".baresip/accounts".text = ''
        <sip:${secrets.voipUsername}@sip1.superloop.com>;auth_pass=${secrets.voipPassword};regint=3600;audio_codecs=PCMA/8000/1,PCMU/8000/1
      '';

      home.file.".baresip/config".text = ''
        # SIP
        sip_listen              0.0.0.0:5060
        sip_cafile              /etc/ssl/certs/ca-certificates.crt

        # Call
        call_max_calls          4
        call_hold_other_calls   yes

        # Audio
        audio_player            alsa,default
        audio_source            alsa,default
        audio_alert             alsa,default
        ausrc_format            s16
        auplay_format           s16

        # AVT
        rtp_tos                 184
        audio_jitter_buffer_type  fixed
        audio_jitter_buffer_ms    100-200
        audio_jitter_buffer_size  50

        # Module path (nixpkgs puts modules here)
        module_path             ${pkgs.baresip}/lib/baresip/modules

        # UI (headless - no GTK)
        module                  stdio.so

        # Audio codecs
        module                  g711.so
        module                  auconv.so
        module                  auresamp.so

        # Audio driver
        module                  alsa.so

        # NAT traversal
        module                  stun.so
        module                  turn.so
        module                  ice.so

        # App modules
        module                  uuid.so
        module_app              account.so
        module_app              contact.so
        module_app              menu.so
        module_app              debug_cmd.so
        module_app              netroam.so
      '';

      systemd.user.services.baresip = {
        Unit = {
          Description = "baresip SIP client";
          After = [ "network.target" ];
          StartLimitIntervalSec = 0;
        };
        Service = {
          ExecStart = "${pkgs.baresip}/bin/baresip -f %h/.baresip";
          Restart = "always";
          RestartSec = 5;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
