{ ... }:

{
  flake.modules.nixos.locale = {
    time.timeZone = "Australia/Perth";

    i18n.defaultLocale = "en_AU.UTF-8";
  };
}
