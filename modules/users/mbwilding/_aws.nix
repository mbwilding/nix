{
  secrets,
  ...
}:

let
  s = secrets.aws;
  output = "yaml";
in
{
  home.sessionVariables = {
    AWS_PROFILE = "default";
    AWS_REGION = s.personal.region;
  };

  programs = {
    awscli = {
      enable = true;
      settings = {
        default = {
          aws_access_key_id = s.personal.id;
          aws_secret_access_key = s.personal.secret;
          region = s.personal.region;
          output = output;
        };
      };
    };
  };
}
