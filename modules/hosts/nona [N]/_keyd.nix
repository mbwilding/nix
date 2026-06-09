{ ... }:

let
  keyThreshold = "200";
in
{
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [
        "0001:0001:09b4e68d"
        "413c:2110:a6c37897"
      ];

      settings = {
        main = {
          backspace = "noop";
          space = "overload(shift, space)";
          capslock = "overload(capslock, backspace)";
          leftshift = "esc";
          rightalt = "layer(symbols)";

          a = "overloadt(control, a, ${keyThreshold})";
          ";" = "overloadt(control, ;, ${keyThreshold})";
          s = "overloadt(meta, s, ${keyThreshold})";
          l = "overloadt(meta, l, ${keyThreshold})";
          z = "overloadt(alt, z, ${keyThreshold})";
          "/" = "overloadt(alt, /, ${keyThreshold})";
          f = "overloadt(numbers, f, ${keyThreshold})";
          m = "overloadt(fkeys, m, ${keyThreshold})";
        };

        "capslock:C" = {
          j = "left";
          c = "down";
          v = "up";
          p = "right";
        };

        "capslock+shift" = {
          j = "C-left";
          c = "C-down";
          v = "C-up";
          p = "C-right";
        };

        symbols = {
          q = "`"; # `
          w = "!"; # !
          e = "?"; # Z
          r = "@"; # @
          t = "{"; # ?
          y = "}"; # +
          u = "~"; # u
          p = "right"; # right
          a = "="; # ]
          s = "|"; # |
          d = "^"; # ^
          f = "_"; # {
          g = "("; # (
          h = ")"; # )
          j = "left"; # left
          k = "$"; # $
          l = "&"; # &
          ";" = "-"; # [
          z = "/"; # z
          x = "#"; # #
          c = "down"; # down
          v = "up"; # up
          b = "{"; # ?
          n = "}"; # +
          m = "+"; # }
          "," = "%"; # !
          "." = "*"; # Z
          "/" = "\\"; # \
        };

        numbers = {
          ";" = "0";
          m = "1";
          "," = "2";
          "." = "3";
          j = "4";
          k = "5";
          l = "6";
          u = "7";
          i = "8";
          o = "9";
        };

        fkeys = {
          q = "f1";
          w = "f2";
          e = "f3";
          r = "f4";
          a = "f5";
          s = "f6";
          d = "f7";
          f = "f8";
          z = "f9";
          x = "f10";
          c = "f11";
          v = "f12";
        };
      };
    };
  };
}
