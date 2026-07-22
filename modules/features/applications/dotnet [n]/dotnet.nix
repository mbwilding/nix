{ ... }:

{
  flake.modules.homeManager.dotnet =
    {
      lib,
      pkgs,
      config,
      ...
    }:
{
      options.custom.dotnet.sdk = lib.mkOption {
        type = lib.types.package;
        default = pkgs.dotnetCorePackages.combinePackages [
          pkgs.dotnetCorePackages.sdk_8_0-bin
          pkgs.dotnetCorePackages.sdk_9_0-bin
          pkgs.dotnetCorePackages.sdk_10_0-bin
          pkgs.dotnetCorePackages.sdk_11_0-bin
        ];
        description = "Combined .NET SDK package shared across all modules";
      };

      config = {
        home = {
          packages = with pkgs; [
            msbuild
          ];

          sessionPath = [
            "$HOME/.dotnet/tools"
            "${config.custom.dotnet.sdk}/bin"
          ];

          sessionVariables = {
            DOTNET_CLI_TELEMETRY_OPTOUT = "1";
            DOTNET_ROOT = "${config.custom.dotnet.sdk}/share/dotnet";
          };

          activation.dotnetSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            dotnet_cmd="${config.custom.dotnet.sdk}/bin/dotnet"

            # dev-certs
            if ! "$dotnet_cmd" dev-certs https --check --quiet 2>/dev/null; then
              "$dotnet_cmd" dev-certs https --trust
            fi

            # dotnet-ef
            if ! "$dotnet_cmd" tool list --global | grep -q "^dotnet-ef"; then
              "$dotnet_cmd" tool install --global dotnet-ef
            fi

            # pac (Power Apps CLI)
            if ! "$dotnet_cmd" tool list --global | grep -qi "^microsoft.powerapps.cli.tool"; then
              "$dotnet_cmd" tool install --global Microsoft.PowerApps.CLI.Tool
            fi

            # dotnet profiling tools
            if ! "$dotnet_cmd" tool list --global | grep -qi "^dotnet-counters"; then
              "$dotnet_cmd" tool install --global dotnet-counters
            fi
            if ! "$dotnet_cmd" tool list --global | grep -qi "^dotnet-gcdump"; then
              "$dotnet_cmd" tool install --global dotnet-gcdump
            fi
            if ! "$dotnet_cmd" tool list --global | grep -qi "^dotnet-trace"; then
              "$dotnet_cmd" tool install --global dotnet-trace
            fi
          '';
        };
      };
    };
}
