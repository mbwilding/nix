{ ... }:

{
  flake.modules.homeManager.onlyoffice =
    { ... }:
    {
      programs = {
        onlyoffice = {
          enable = true;
          settings = {
            UITheme = "theme-night";
            appdata = "@ByteArray(eyJ1c2VybmFtZSI6Im1id2lsZGluZyIsImRvY29wZW5tb2RlIjoiZWRpdCIsInJlc3RhcnQiOmZhbHNlLCJsYW5naWQiOiJlbi1HQiIsInVpc2NhbGluZyI6IjE1MCIsInVpdGhlbWUiOiJ0aGVtZS1uaWdodCIsImVkaXRvcndpbmRvd21vZGUiOnRydWUsInNwZWxsY2hlY2tkZXRlY3QiOiJhdXRvIiwidXNlZ3B1Ijp0cnVlfQ==)";
            editorWindowMode = true;
            locale = "en-GB";
            titlebar = "custom";
          };
        };
      };

      home.activation = {
        copy-fonts-local-share = ''
          mkdir -p ~/.local/share/fonts
          chmod 744 ~/.local/share/fonts
          while IFS= read -r fontDir; do
            find "$fontDir" -type f \( -iname "*.ttf" -o -iname "*.otf" \) \
              -exec cp -u {} ~/.local/share/fonts/ \;
          done < <(grep -oP '(?<=<dir>)[^<]+(?=</dir>)' /etc/fonts/conf.d/00-nixos-cache.conf)
        '';
      };
    };
}
