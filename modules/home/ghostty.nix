{
  lib,
  config,
  hostname,
  font,
  ...
}:

let
  mod = "super+shift+ctrl+alt";
  shaders = {
    color = "vec4(0.35, 0.25375, 0.05635, 1.0)";
    colorAccent = "vec4(0.35, 0.0, 0.0, 1.0)";
    duration = "0.05";
    blaze = false;
    trail = false;
  };
in
{
  programs = {
    ghostty = {
      enable = true;
      systemd.enable = true;
      enableFishIntegration = config.programs.fish.enable;
      enableZshIntegration = config.programs.zsh.enable;
      installBatSyntax = true;
      installVimSyntax = true;
      clearDefaultKeybinds = true;
      settings = {
        custom-shader =
          (lib.optionals shaders.trail [ "shaders/cursor_smear.glsl" ])
          ++ (lib.optionals shaders.blaze [ "shaders/cursor_blaze.glsl" ]);

        font-family = font;
        # font-family = "JetBrains Mono Nerd Font";
        font-size = if hostname == "anon" then 19 else 17;
        font-synthetic-style = true;
        # adjust-cell-width = "-5%";
        adjust-cell-height = "15%";
        adjust-underline-position = 4;
        background-opacity = 0.95;
        clipboard-paste-protection = false;
        clipboard-read = "allow";
        clipboard-trim-trailing-spaces = true;
        clipboard-write = "allow";
        confirm-close-surface = false;
        copy-on-select = true;
        cursor-click-to-move = true;
        # selection-foreground="cell-background";
        # selection-background="cell-foreground";
        cursor-color = "cell-foreground";
        cursor-text = "cell-background";
        cursor-opacity = 1.0;
        cursor-style = "block";
        cursor-style-blink = true;
        focus-follows-mouse = true;
        gtk-tabs-location = "top";
        gtk-titlebar = false;
        mouse-hide-while-typing = true;
        mouse-shift-capture = false;
        quit-after-last-window-closed = true;
        quit-after-last-window-closed-delay = "5m";
        resize-overlay = "never";
        shell-integration =
          if config.programs.fish.enable then
            "fish"
          else if config.programs.zsh.enable then
            "zsh"
          else
            "none";
        # shell-integration-features = "cursor,sudo,title,ssh-terminfo,ssh-env";
        shell-integration-features = "cursor,sudo,title";
        theme = "gronk";
        window-decoration = "server";
        window-padding-balance = false;
        window-padding-x = 5;
        window-padding-y = 5;
        window-theme = "ghostty";
        # quick-terminal-position = "top";
        # quick-terminal-size = "30%";
        # quick-terminal-autohide = false;
        # gtk-quick-terminal-layer = "overlay";

        keybind = [
          "ctrl+0=reset_font_size"
          "ctrl+equal=increase_font_size:1"
          "ctrl+minus=decrease_font_size:1"
          "f11=toggle_fullscreen"
          # "f1=toggle_quick_terminal"
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

  home = {
    file = {
      ".config/ghostty/shaders/cursor_blaze.glsl".text = ''
        float sdBox(in vec2 p, in vec2 xy, in vec2 b)
        {
            vec2 d = abs(p - xy) - b;
            return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
        }

        vec2 normalize(vec2 value, float isPosition) {
            return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
        }

        float ParametricBlend(float t)
        {
            float sqr = t * t;
            return sqr / (2.0 * (sqr - t) + 1.0);
        }

        float determineStartVertexFactor(vec2 a, vec2 b) {
            // Conditions using step
            float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
            float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

            // If neither condition is met, return 1 (else case)
            return 1.0 - max(condition1, condition2);
        }

        // const vec4 TRAIL_COLOR = vec4(0.482, 0.886, 1.0, 1.0);
        // const vec4 TRAIL_COLOR_ACCENT = vec4(0.0, 0.424, 1.0, 1.0);
        const vec4 TRAIL_COLOR = ${shaders.color};
        const vec4 TRAIL_COLOR_ACCENT = ${shaders.colorAccent};
        const vec4 CURRENT_CURSOR_COLOR = TRAIL_COLOR;
        const vec4 PREVIOUS_CURSOR_COLOR = TRAIL_COLOR;
        const float DURATION = ${shaders.duration};

        void mainImage(out vec4 fragColor, in vec2 fragCoord)
        {
            #if !defined(WEB)
            fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
            #endif

            //Normalization for fragCoord to a space of -1 to 1;
            vec2 vu = normalize(fragCoord, 1.);
            vec2 offsetFactor = vec2(-.5, 0.5);

            //Normalization for cursor position and size;
            //cursor xy has the postion in a space of -1 to 1;
            //zw has the width and height
            vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
            vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

            //When drawing a parellelogram between cursors for the trail i need to determine where to start at the top-left or top-right vertex of the cursor
            float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
            float invertedVertexFactor = 1.0 - vertexFactor;

            //Set every vertex of my parellogram
            vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
            vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
            vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
            vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

            vec4 newColor = vec4(fragColor);

            float progress = ParametricBlend(clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0));

            //Distance between cursors determine the total length of the parallelogram;
            float lineLength = distance(currentCursor.xy, previousCursor.xy);
            float distanceToEnd = distance(vu.xy, vec2(currentCursor.x + (currentCursor.z / 2.), currentCursor.y - (currentCursor.w / 2.)));
            float alphaModifier = distanceToEnd / (lineLength * (1.0 - progress));

            float cCursorDistance = sdBox(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
            newColor = mix(newColor, TRAIL_COLOR_ACCENT, 1.0 - smoothstep(cCursorDistance, -0.000, 0.003 * (1. - progress)));
            newColor = mix(newColor, CURRENT_CURSOR_COLOR, 1.0 - smoothstep(cCursorDistance, -0.000, 0.003 * (1. - progress)));

            fragColor = mix(fragColor, newColor, 1.);
        }
      '';

      ".config/ghostty/shaders/cursor_smear.glsl".text = ''
        float getSdfRectangle(in vec2 p, in vec2 xy, in vec2 b)
        {
            vec2 d = abs(p - xy) - b;
            return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
        }

        // Based on Inigo Quilez's 2D distance functions article: https://iquilezles.org/articles/distfunctions2d/
        // Potencially optimized by eliminating conditionals and loops to enhance performance and reduce branching

        float seg(in vec2 p, in vec2 a, in vec2 b, inout float s, float d) {
            vec2 e = b - a;
            vec2 w = p - a;
            vec2 proj = a + e * clamp(dot(w, e) / dot(e, e), 0.0, 1.0);
            float segd = dot(p - proj, p - proj);
            d = min(d, segd);

            float c0 = step(0.0, p.y - a.y);
            float c1 = 1.0 - step(0.0, p.y - b.y);
            float c2 = 1.0 - step(0.0, e.x * w.y - e.y * w.x);
            float allCond = c0 * c1 * c2;
            float noneCond = (1.0 - c0) * (1.0 - c1) * (1.0 - c2);
            float flip = mix(1.0, -1.0, step(0.5, allCond + noneCond));
            s *= flip;
            return d;
        }

        float getSdfParallelogram(in vec2 p, in vec2 v0, in vec2 v1, in vec2 v2, in vec2 v3) {
            float s = 1.0;
            float d = dot(p - v0, p - v0);

            d = seg(p, v0, v3, s, d);
            d = seg(p, v1, v0, s, d);
            d = seg(p, v2, v1, s, d);
            d = seg(p, v3, v2, s, d);

            return s * sqrt(d);
        }

        vec2 normalize(vec2 value, float isPosition) {
            return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
        }

        float antialising(float distance) {
            return 1. - smoothstep(0., normalize(vec2(2., 2.), 0.).x, distance);
        }

        float determineStartVertexFactor(vec2 a, vec2 b) {
            // Conditions using step
            float condition1 = step(b.x, a.x) * step(a.y, b.y); // a.x < b.x && a.y > b.y
            float condition2 = step(a.x, b.x) * step(b.y, a.y); // a.x > b.x && a.y < b.y

            // If neither condition is met, return 1 (else case)
            return 1.0 - max(condition1, condition2);
        }

        vec2 getRectangleCenter(vec4 rectangle) {
            return vec2(rectangle.x + (rectangle.z / 2.), rectangle.y - (rectangle.w / 2.));
        }
        float ease(float x) {
            return pow(1.0 - x, 3.0);
        }

        const vec4 TRAIL_COLOR = ${shaders.color};
        const float DURATION = ${shaders.duration}; //IN SECONDS

        void mainImage(out vec4 fragColor, in vec2 fragCoord)
        {
            #if !defined(WEB)
            fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
            #endif
            // Normalization for fragCoord to a space of -1 to 1;
            vec2 vu = normalize(fragCoord, 1.);
            vec2 offsetFactor = vec2(-.5, 0.5);

            // Normalization for cursor position and size;
            // cursor xy has the postion in a space of -1 to 1;
            // zw has the width and height
            vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
            vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

            // When drawing a parellelogram between cursors for the trail i need to determine where to start at the top-left or top-right vertex of the cursor
            float vertexFactor = determineStartVertexFactor(currentCursor.xy, previousCursor.xy);
            float invertedVertexFactor = 1.0 - vertexFactor;

            // Set every vertex of my parellogram
            vec2 v0 = vec2(currentCursor.x + currentCursor.z * vertexFactor, currentCursor.y - currentCursor.w);
            vec2 v1 = vec2(currentCursor.x + currentCursor.z * invertedVertexFactor, currentCursor.y);
            vec2 v2 = vec2(previousCursor.x + currentCursor.z * invertedVertexFactor, previousCursor.y);
            vec2 v3 = vec2(previousCursor.x + currentCursor.z * vertexFactor, previousCursor.y - previousCursor.w);

            float sdfCurrentCursor = getSdfRectangle(vu, currentCursor.xy - (currentCursor.zw * offsetFactor), currentCursor.zw * 0.5);
            float sdfTrail = getSdfParallelogram(vu, v0, v1, v2, v3);

            float progress = clamp((iTime - iTimeCursorChange) / DURATION, 0.0, 1.0);
            float easedProgress = ease(progress);
            // Distance between cursors determine the total length of the parallelogram;
            vec2 centerCC = getRectangleCenter(currentCursor);
            vec2 centerCP = getRectangleCenter(previousCursor);
            float lineLength = distance(centerCC, centerCP);

            vec4 newColor = vec4(fragColor);
            // Compute fade factor based on distance along the trail
            float fadeFactor = 1.0 - smoothstep(lineLength, sdfCurrentCursor, easedProgress * lineLength);

            // Apply fading effect to trail color
            vec4 fadedTrailColor = TRAIL_COLOR * fadeFactor;

            // Blend trail with fade effect
            newColor = mix(newColor, fadedTrailColor, antialising(sdfTrail));
            // Draw current cursor
            newColor = mix(newColor, TRAIL_COLOR, antialising(sdfCurrentCursor));
            newColor = mix(newColor, fragColor, step(sdfCurrentCursor, 0.));
            fragColor = mix(fragColor, newColor, step(sdfCurrentCursor, easedProgress * lineLength));
        }
      '';
    };
  };
}
