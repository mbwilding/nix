{ ... }:

{
  flake.modules.homeManager.package-managers =
    { secrets, ... }:

    {
      home = {
        file.".nuget/NuGet/NuGet.Config".text = ''
          <?xml version="1.0" encoding="utf-8"?>
          <configuration>
            <packageSources>
              <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
              <add key="github" value="https://nuget.pkg.github.com/${secrets.workName}/index.json" />
            </packageSources>
            <packageSourceCredentials>
              <github>
                <add key="Username" value="${secrets.githubWorkUsername}" />
                <add key="ClearTextPassword" value="${secrets.githubWorkToken}" />
              </github>
            </packageSourceCredentials>
          </configuration>
        '';

        file.".config/.bunfig.toml".text = ''
          [install.scopes."@${secrets.workName}"]
          url = "https://npm.pkg.github.com"
          token = "${secrets.githubWorkToken}"
        '';

        file.".config/.npmrc".text = ''
          @${secrets.workName}:registry=https://npm.pkg.github.com
          //npm.pkg.github.com/:_authToken=${secrets.githubWorkToken}
        '';

        file.".config/.yarnrc.yml".text = ''
          npmScopes:
            "${secrets.workName}":
              npmRegistryServer: "https://npm.pkg.github.com"
              npmAuthToken: "${secrets.githubWorkToken}"
        '';
      };
    };
}
