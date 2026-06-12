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
    { config, pkgs, ... }:
    let
      dataDir = "${config.home.homeDirectory}/.var/app/com.core447.StreamController/data";

      copyOnce =
        name: dest: content:
        let
          file = pkgs.writeText name content;
        in
        ''
          if [ ! -e "${dest}" ]; then
            mkdir -p "$(dirname "${dest}")"
            cp ${file} "${dest}"
            chmod 644 "${dest}"
          fi
        '';
    in
    {
      home.activation.streamcontrollerFiles = config.lib.dag.entryAfter [ "writeBoundary" ] (
        copyOnce "streamcontroller-skip-onboarding" "${dataDir}/.skip-onboarding" ""
        + copyOnce "streamcontroller-settings" "${dataDir}/settings/settings.json" ''
          {
              "general": {
                  "app-launches": 6,
                  "default-font": {
                      "font-family": "NeoSpleen",
                      "font-size": 15.0,
                      "font-weight": 400,
                      "font-style": "normal"
                  }
              },
              "store": {
                  "responsibility-notes-agreed": true
              },
              "system": {
                  "keep-running": true,
                  "autostart": false
              },
              "ui": {
                  "auto-open-action-config": true
              }
          }
        ''
        + copyOnce "streamcontroller-main-page" "${dataDir}/settings/pages.json" ''
          {
              "default-pages": {
                  "A00SA3402O5JYX": "${dataDir}/pages/Main.json"
              }
          }
        ''
        + copyOnce "streamcontroller-main-page" "${dataDir}/pages/Main.json" ''
          {
              "keys": {
                  "0x0": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_MicMute::ToggleMute",
                                      "settings": {
                                          "all": true,
                                          "device": null
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "1x0": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_memclash_elgatokeylight::ToggleButton",
                                      "settings": {
                                          "ip_address": "192.168.11.192"
                                      },
                                      "comment": "Left"
                                  },
                                  {
                                      "id": "com_memclash_elgatokeylight::ToggleButton",
                                      "settings": {
                                          "ip_address": "192.168.11.191"
                                      },
                                      "comment": "Right"
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "1x1": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_OSPlugin::RAM",
                                      "settings": {}
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0,
                              "labels": {
                                  "bottom": {
                                      "text": "RAM"
                                  }
                              }
                          }
                      }
                  },
                  "0x1": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_OSPlugin::CPU",
                                      "settings": {}
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0,
                              "labels": {
                                  "bottom": {
                                      "text": "CPU"
                                  }
                              }
                          }
                      }
                  },
                  "2x1": {},
                  "3x1": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_Countdown::Countdown",
                                      "settings": {
                                          "duration": 60
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "4x2": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_Clocks::DigitalClock",
                                      "settings": {
                                          "twenty-four-format": false,
                                          "show-seconds": false
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "3x2": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_Clocks::DigitalClock",
                                      "settings": {
                                          "show-seconds": true
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "2x2": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_Clocks::Date",
                                      "settings": {
                                          "label-position": "center",
                                          "key": "%d-%m"
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0,
                              "labels": {
                                  "center": {
                                      "font-family": "DejaVu Sans",
                                      "style": "normal",
                                      "font-size": 20.0,
                                      "font-weight": 400
                                  }
                              }
                          }
                      }
                  },
                  "1x2": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_Weather::Weather",
                                      "settings": {
                                          "lat": "-31.871026171903267",
                                          "lon": "115.83659755889765"
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "2x0": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "steam::ChangeStatus",
                                      "settings": {
                                          "committed_status": "invisible"
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "0x2": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_OSPlugin::CPUTemp",
                                      "settings": {}
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0,
                              "labels": {
                                  "bottom": {
                                      "text": "CPU"
                                  }
                              }
                          }
                      }
                  },
                  "4x1": {
                      "states": {
                          "0": {
                              "actions": [
                                  {
                                      "id": "com_core447_Counter::Counter",
                                      "settings": {
                                          "value": 0
                                      }
                                  }
                              ],
                              "image-control-action": 0,
                              "label-control-actions": [
                                  0,
                                  0,
                                  0
                              ],
                              "background-control-action": 0
                          }
                      }
                  },
                  "4x0": {},
                  "3x0": {}
              }
          }
        ''
      );
    };
}
