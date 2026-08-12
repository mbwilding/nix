{ secrets, lib, ... }:
{
  programs = {
    lazysql = {
      settings = {
        database = [
          {
            Name = "Local Dev";
            URL = "postgres://postgres:Developer01@127.0.0.1?sslmode=disable";
            Provider = "postgres";
          }
          {
            Name = "Devl";
            URL = "postgres://${secrets.databases.devl.username}:${lib.escapeURL secrets.databases.devl.password}@${secrets.databases.devl.host}:${secrets.databases.devl.port}";
            Provider = "postgres";
          }
        ];
      };
    };
  };
}
