{ secrets, ... }:

{
  imports = [
    # ./zsh.nix
    # ./starship.nix
    ./aliases.nix
    ./fish.nix
  ];

  home = {
    sessionPath = [ "$HOME/.cargo/bin" ];

    sessionVariables = {
      ANTHROPIC_API_KEY = secrets.anthropicKey;
      ATLASSIAN_API_TOKEN = secrets.atlassianKey;
      CARGO_REGISTRY_TOKEN = secrets.cargoToken;
      DEEPSEEK_API_KEY = secrets.deepSeekKey;
      ELEVENLABS_API_KEY = secrets.elevenLabsKey;
      GITHUB_TOKEN = secrets.githubWorkToken;
      GITHUB_TOKEN_PERSONAL = secrets.githubPersonalToken;
      GITHUB_TOKEN_WORK = secrets.githubWorkToken;
      GITLAB_TOKEN = secrets.gitlabWorkToken;
      GITLAB_TOKEN_WORK = secrets.gitlabWorkToken;
      OPENAI_API_KEY = secrets.openAiKey;
      PULUMI_ACCESS_TOKEN = secrets.pulumiToken;
      STEAM_API_KEY = secrets.steamToken;
      WEATHER_API_TOKEN = secrets.weatherKey;
    };
  };
}
