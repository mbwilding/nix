{ ... }:

{
  flake.modules.nixos.groups =
    { lib, config, ... }:
    {
      options.custom = {
        availableGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Groups that feature modules declare they provide. All managedUsers will be added to these.";
        };

        managedUsers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Users that should automatically receive all availableGroups.";
        };
      };

      config = lib.mkIf (config.custom.managedUsers != [ ]) {
        users.users = lib.genAttrs config.custom.managedUsers (_user: {
          extraGroups = config.custom.availableGroups;
        });
      };
    };
}
