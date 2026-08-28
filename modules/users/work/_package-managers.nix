{ secrets, ... }:

{
  home = {
    file = {
      ".nuget/NuGet/NuGet.Config".text = ''
        <?xml version="1.0" encoding="utf-8"?>
        <configuration>
          <packageSources>
            <add key="nuget.org" value="https://api.nuget.org/v3/index.json" protocolVersion="3" />
            <add key="github" value="https://nuget.pkg.github.com/${secrets.workName}/index.json" />
            <add key="artifactory" value="https://artifactory.internal.${secrets.workName}.delivery/artifactory/api/nuget/v3/nuget-all/index.json" />
          </packageSources>
          <packageSourceCredentials>
            <github>
              <add key="Username" value="${secrets.githubWorkUsername}" />
              <add key="ClearTextPassword" value="${secrets.githubWorkToken}" />
            </github>
            <artifactory>
              <add key="Username" value="${secrets.workId}" />
              <add key="ClearTextPassword" value="${secrets.artifactory}" />
            </artifactory>
          </packageSourceCredentials>
        </configuration>
      '';

      ".config/.bunfig.toml".text = ''
        [install.scopes."@${secrets.workName}"]
        url = "https://npm.pkg.github.com"
        token = "${secrets.githubWorkToken}"
      '';

      ".config/.npmrc".text = ''
        @${secrets.workName}:registry=https://npm.pkg.github.com
        //npm.pkg.github.com/:_authToken=${secrets.githubWorkToken}
      '';

      ".config/.yarnrc.yml".text = ''
        npmScopes:
          "${secrets.workName}":
            npmRegistryServer: "https://npm.pkg.github.com"
            npmAuthToken: "${secrets.githubWorkToken}"
      '';

      ".cargo/config.toml".text = ''
        [registries.kellnr]
        index = "sparse+https://crates.internal.${secrets.workName}.delivery/api/v1/crates/"
        credential-provider = ["cargo:token"]

        [registry]
        default = "kellnr"
      '';

      ".cargo/credentials.toml".text = ''
        [registries.kellnr]
        token = "${secrets.cratesWorkToken}"
      '';
    };
  };
}
