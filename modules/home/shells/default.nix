{ secrets, ... }:

{
  imports = [
    # ./zsh.nix
    # ./starship.nix
    ./aliases.nix
    ./fish.nix
  ];

  home.sessionVariables = {
    GITLAB_TOKEN = secrets.gitlabWorkToken;
    GITLAB_TOKEN_WORK = secrets.gitlabWorkToken;
    GITHUB_TOKEN = secrets.githubWorkToken;
    GITHUB_TOKEN_WORK = secrets.githubWorkToken;
    GITHUB_TOKEN_PERSONAL = secrets.githubPersonalToken;
    CARGO_REGISTRY_TOKEN = secrets.cargoToken;
    ELEVENLABS_API_KEY = secrets.elevenLabsKey;
    PULUMI_ACCESS_TOKEN = secrets.pulumiToken;
    STEAM_API_KEY = secrets.steamToken;
    WEATHER_API_TOKEN = secrets.weatherKey;
    ANTHROPIC_API_KEY = secrets.anthropicKey;
    DEEPSEEK_API_KEY = secrets.deepSeekKey;
    OPENAI_API_KEY = secrets.openAiKey;
  };
}
