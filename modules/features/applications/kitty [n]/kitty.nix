{ ... }:

{
  flake.modules.homeManager.kitty =
    {
      lib,
      config,
      ...
    }:

    let
      mod = "ctrl+shift+alt+super";
    in
    {
      programs = {
        kitty = {
          enable = true;
          shellIntegration = {
            enableFishIntegration = config.programs.fish.enable;
            enableZshIntegration = config.programs.zsh.enable;
          };

          font = {
            name = "NeoSpleen Nerd Font";
            size = 17;
          };

          settings = {
            adjust_line_height = "115%";
            background_opacity = "0.91";
            clear_all_shortcuts = true;
            confirm_os_window_close = 0;
            copy_on_select = "clipboard";
            cursor_shape = "block";
            cursor = "#bdbdbd";
            cursor_text_color = "#000000";
            focus_follows_mouse = true;
            hide_window_decorations = true;
            strip_trailing_spaces = "always";
            window_padding_width = 5;

            background = "#000000";
            foreground = "#bdbdbd";
            selection_background = "#64a4c4";
            selection_foreground = "#000000";
            color0 = "#181818";
            color1 = "#e78284";
            color2 = "#39cc84";
            color3 = "#c9a26d";
            color4 = "#8caaee";
            color5 = "#f4b8e4";
            color6 = "#81c8be";
            color7 = "#a5adce";
            color8 = "#4f5258";
            color9 = "#ff4747";
            color10 = "#39cc8f";
            color11 = "#ffffff";
            color12 = "#9591ff";
            color13 = "#ed94c0";
            color14 = "#5abfb5";
            color15 = "#b5bfe2";
          };

          keybindings = {
            "ctrl+0" = "change_font_size all 0";
            "ctrl+equal" = "change_font_size all +1.0";
            "ctrl+minus" = "change_font_size all -1.0";
            "f11" = "toggle_fullscreen";
            "${mod}+a" = "goto_tab 1";
            "${mod}+o" = "goto_tab 2";
            "${mod}+e" = "goto_tab 3";
            "${mod}+u" = "goto_tab 4";
            "${mod}+i" = "goto_tab 5";
            "${mod}+c" = "copy_to_clipboard";
            "${mod}+comma" = "move_tab_backward";
            "${mod}+m" = "toggle_layout stack";
            "${mod}+n" = "next_tab";
            "${mod}+l" = "next_tab";
            "${mod}+p" = "previous_tab";
            "${mod}+h" = "previous_tab";
            "${mod}+period" = "move_tab_forward";
            "${mod}+t" = "new_tab";
            "${mod}+v" = "paste_from_clipboard";
            "${mod}+q" = "close_window";
            "${mod}+w" = "close_tab";
            "${mod}+z" = "show_scrollback";
          } // builtins.listToAttrs (
            builtins.genList (i: {
              name = "${mod}+${toString (i + 1)}";
              value = "goto_tab ${toString (i + 1)}";
            }) 9
          );
        };
      };
    };
}
