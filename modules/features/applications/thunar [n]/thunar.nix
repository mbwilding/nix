{ ... }:

{
  flake.modules.homeManager.thunar =
    { pkgs, ... }:

    {
      home = {
        packages = with pkgs; [
          thunar
          thunar-archive-plugin
          thunar-volman
          ffmpegthumbnailer

          # Optional, for PDFs
          poppler

          # Optional, for RAW camera images
          libraw
        ];
      };

      xdg.configFile."Thunar/uca.xml".text = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <actions>
          <action>
            <icon>utilities-terminal</icon>
            <name>Open Kitty Here</name>
            <unique-id>1754460000000000-1</unique-id>
            <command>kitty --directory %f</command>
            <description>Open Kitty in this folder</description>
            <patterns>*</patterns>
            <directories/>
          </action>
        </actions>
      '';
    };
}
