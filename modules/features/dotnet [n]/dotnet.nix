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
        default = pkgs.symlinkJoin {
          name = "dotnet-combined";
          paths = [
            # pkgs.dotnet-sdk_11
            # pkgs.dotnet-sdk_10
            # pkgs.dotnet-sdk_8
            pkgs.dotnet-sdk_9
            # pkgs.dotnet-aspnetcore_11
            # pkgs.dotnet-aspnetcore_10
            # pkgs.dotnet-aspnetcore_8
            pkgs.dotnet-aspnetcore_9
            # pkgs.dotnet-runtime_11
            # pkgs.dotnet-runtime_10
            # pkgs.dotnet-runtime_8
            pkgs.dotnet-runtime_9
          ];
        };
        description = "Combined .NET SDK package shared across all modules.";
      };

      config.home = {
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

          # Generate dev-certs if not already present
          if ! "$dotnet_cmd" dev-certs https --check --quiet 2>/dev/null; then
            "$dotnet_cmd" dev-certs https --trust
          fi

          # Install dotnet-ef if not already installed
          if ! "$dotnet_cmd" tool list --global | grep -q "^dotnet-ef"; then
            "$dotnet_cmd" tool install --global dotnet-ef
          fi
        '';
      };
    };
}
