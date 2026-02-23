{ ... }:

let
  mod = "super+shift+ctrl+alt";
in
{
  programs = {
    ghostty = {
      enable = true;
      systemd.enable = true;
      enableZshIntegration = true;
      installBatSyntax = true;
      installVimSyntax = true;
      clearDefaultKeybinds = true;
      settings = {
        adjust-cell-height = "12%";
        adjust-cell-width = "-8%";
        adjust-cursor-height = "12%";
        adjust-underline-position = 4;
        background-opacity = 0.85;
        clipboard-paste-protection = false;
        clipboard-read = "allow";
        clipboard-trim-trailing-spaces = true;
        clipboard-write = "allow";
        confirm-close-surface = false;
        copy-on-select = true;
        cursor-click-to-move = true;
        cursor-invert-fg-bg = true;
        cursor-opacity = 1.0;
        cursor-style = "block";
        cursor-style-blink = true;
        focus-follows-mouse = true;
        font-family = "NeoSpleen Nerd Font";
        font-size = 21;
        # font-synthetic-style = true;
        gtk-tabs-location = "top";
        gtk-titlebar = false;
        mouse-hide-while-typing = true;
        mouse-shift-capture = false;
        quit-after-last-window-closed = true;
        resize-overlay = "never";
        shell-integration = "zsh";
        # shell-integration-features = "cursor,sudo,title,ssh-terminfo,ssh-env";
        shell-integration-features = "cursor,sudo,title";
        theme = "gronk";
        window-decoration = "server";
        window-padding-balance = false;
        window-padding-x = 0;
        window-padding-y = 0;
        window-theme = "ghostty";
        keybind = [
          "ctrl+0=reset_font_size"
          "ctrl+equal=increase_font_size:1"
          "ctrl+minus=decrease_font_size:1"
          "f11=toggle_fullscreen"
          "${mod}+a=goto_tab:1"
          "${mod}+o=goto_tab:2"
          "${mod}+e=goto_tab:3"
          "${mod}+u=goto_tab:4"
          "${mod}+i=goto_tab:5"
          "${mod}+c=copy_to_clipboard"
          "${mod}+comma=move_tab:-1"
          "${mod}+m=toggle_split_zoom"
          "${mod}+n=next_tab"
          "${mod}+l=next_tab"
          "${mod}+p=previous_tab"
          "${mod}+h=previous_tab"
          "${mod}+period=move_tab:1"
          "${mod}+t=new_tab"
          "${mod}+v=paste_from_clipboard"
          "${mod}+q=close_surface"
          "${mod}+w=close_tab"
          "${mod}+z=write_screen_file:open"
          "${mod}+i=inspector:toggle"
        ]
        ++ (builtins.genList (i: "${mod}+${toString (i + 1)}=goto_tab:${toString (i + 1)}") 9);
      };
      themes = {
        gronk = {
          background = "#000000";
          foreground = "#bdbdbd";
          selection-background = "#64a4c4";
          selection-foreground = "#000000";
          cursor-color = "#bdbdbd";
          palette = [
            "0=#181818"
            "1=#e78284"
            "2=#39cc84"
            "3=#c9a26d"
            "4=#8caaee"
            "5=#f4b8e4"
            "6=#81c8be"
            "7=#a5adce"
            "8=#4f5258"
            "9=#ff4747"
            "10=#39cc8f"
            "11=#ffffff"
            "12=#9591ff"
            "13=#ed94c0"
            "14=#5abfb5"
            "15=#b5bfe2"
          ];
        };
      };
    };
  };
}
