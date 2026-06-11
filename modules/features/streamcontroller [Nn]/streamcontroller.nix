{ ... }:

{
  flake.modules.nixos.streamcontroller =
    { pkgs, ... }:
    {
      environment.systemPackages = [ pkgs.streamcontroller ];

      services.udev.extraRules = ''
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0060", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0063", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006c", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="006d", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0080", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0084", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0086", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="008f", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="0090", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="009a", TAG+="uaccess"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0fd9", ATTRS{idProduct}=="00a5", TAG+="uaccess"
      '';
    };

  flake.modules.homeManager.streamcontroller =
    { ... }:
    {
      home.file = {
        ".var/app/com.core447.StreamController/data/.skip-onboarding".text = ""; # ".var/app/com.core447.StreamController/data/settings/settings.json".text = builtins.toJSON {
        #   general = {
        #     "app-launches" = 1;
        #   };
        #   system = {
        #     "keep-running" = true;
        #   };
        #   store = {
        #     "responsibility-notes-agreed" = true;
        #   };
        # };

        # ".var/app/com.core447.StreamController/data/pages/Main.json".text = builtins.toJSON {
        #   keys = {
        #     "0x0" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_MicMute::ToggleMute";
        #               settings = {
        #                 all = true;
        #                 device = null;
        #               };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #         };
        #       };
        #     };
        #     "1x0" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_memclash_elgatokeylight::ToggleButton";
        #               settings = {
        #                 ip_address = "192.168.11.191";
        #               };
        #             }
        #             {
        #               id = "com_memclash_elgatokeylight::ToggleButton";
        #               settings = {
        #                 ip_address = "192.168.11.192";
        #               };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #         };
        #       };
        #     };
        #     "4x2" = {
        #       states = {
        #         "0" = {
        #           background = {
        #             color = [ 0 0 0 255 ];
        #           };
        #           actions = [
        #             {
        #               id = "com_core447_Clocks::AnalogClock";
        #               settings = { };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #         };
        #       };
        #     };
        #     "3x2" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_Clocks::DigitalClock";
        #               settings = {
        #                 "twenty-four-format" = false;
        #               };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #           labels = {
        #             center = {
        #               "font-family" = "NeoSpleen";
        #               style = "normal";
        #               "font-size" = 18.0;
        #               "font-weight" = 400;
        #             };
        #             bottom = {
        #               "font-family" = "NeoSpleen";
        #               style = "normal";
        #               "font-size" = 18.0;
        #               "font-weight" = 400;
        #             };
        #           };
        #         };
        #       };
        #     };
        #     "1x1" = { };
        #     "4x0" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_OSPlugin::RAM";
        #               settings = { };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #           labels = {
        #             center = {
        #               "font-family" = "NeoSpleen";
        #               style = "normal";
        #               "font-size" = 24.0;
        #               "font-weight" = 400;
        #             };
        #           };
        #         };
        #       };
        #     };
        #     "3x0" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_OSPlugin::CPU";
        #               settings = { };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #           labels = {
        #             center = {
        #               "font-family" = "DejaVu Sans";
        #               style = "normal";
        #               "font-size" = 24.0;
        #               "font-weight" = 400;
        #             };
        #           };
        #         };
        #       };
        #     };
        #     "2x0" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_OSPlugin::CPUTemp";
        #               settings = { };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #           labels = {
        #             center = {
        #               "font-family" = "NeoSpleen";
        #               style = "normal";
        #               "font-size" = 18.0;
        #               "font-weight" = 400;
        #             };
        #           };
        #         };
        #       };
        #     };
        #     "2x2" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_Clocks::Date";
        #               settings = {
        #                 key = "%d-%m";
        #               };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #           labels = {
        #             center = {
        #               "font-family" = "DejaVu Sans";
        #               style = "normal";
        #               "font-size" = 19.0;
        #               "font-weight" = 400;
        #             };
        #           };
        #         };
        #       };
        #     };
        #     "0x2" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_Battery::BatteryPercentage";
        #               settings = {
        #                 device = "L23D4PF1";
        #               };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #         };
        #       };
        #     };
        #     "1x2" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_codeNinja_DaysUntil::DaysUntilAction";
        #               settings = {
        #                 date_format_ymd = true;
        #                 bottom_label = "Holiday";
        #                 target_date = "2026/07/24";
        #               };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #           labels = {
        #             bottom = {
        #               "font-family" = "cantarell";
        #               style = "normal";
        #               "font-size" = 15.0;
        #               "font-weight" = 400;
        #             };
        #             center = {
        #               "font-family" = "cantarell";
        #               style = "normal";
        #               "font-size" = 15.0;
        #               "font-weight" = 400;
        #             };
        #             top = {
        #               "font-family" = "NeoSpleen";
        #               style = "normal";
        #               "font-size" = 14.0;
        #               "font-weight" = 400;
        #             };
        #           };
        #         };
        #       };
        #     };
        #     "3x1" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_OSPlugin::CPU_Graph";
        #               settings = { };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #         };
        #       };
        #     };
        #     "2x1" = { };
        #     "4x1" = {
        #       states = {
        #         "0" = {
        #           actions = [
        #             {
        #               id = "com_core447_OSPlugin::RAM_Graph";
        #               settings = { };
        #             }
        #           ];
        #           "image-control-action" = 0;
        #           "label-control-actions" = [ 0 0 0 ];
        #           "background-control-action" = 0;
        #         };
        #       };
        #     };
        #   };
        # };
      };
    };
}
