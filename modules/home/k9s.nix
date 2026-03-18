{ ... }:

{
  programs = {
    k9s = {
      enable = true;
      settings = {
        k9s = {
          namespace = "all";
          ui = {
            skin = "dark";
          };
          refreshRate = 2;
        };
      };
    };
  };
}
