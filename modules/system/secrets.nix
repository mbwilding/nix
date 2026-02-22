let
  readSecret =
    path:
    if builtins.pathExists path then builtins.readFile path else throw "Secret file not found: ${path}";

  readSecretJSON =
    path:
    if builtins.pathExists path then
      builtins.fromJSON (builtins.readFile path)
    else
      throw "Secret JSON file not found: ${path}";
in
{
  # SSH keys
  personalPublicKey = readSecret /home/anon/.ssh/personal.pub;
  workPublicKey = readSecret /home/anon/.ssh/work.pub;

  # Work identity
  workName = readSecret /home/anon/.secrets/work-name;
  workId = readSecret /home/anon/.secrets/work-id;
  workEmailName = readSecret /home/anon/.secrets/work-email-name;
  workEmailId = readSecret /home/anon/.secrets/work-email-id;

  # GitHub
  githubWorkUsername = readSecret /home/anon/.secrets/github-work-username;
  githubWorkToken = readSecret /home/anon/.secrets/github-work;
  githubPersonalToken = readSecret /home/anon/.secrets/github-personal;

  # GitLab
  gitlabWorkToken = readSecret /home/anon/.secrets/gitlab-work;

  # Cargo
  cargoToken = readSecret /home/anon/.secrets/cargo;

  # API keys
  anthropicKey = readSecret /home/anon/.secrets/anthropic;
  deepSeekKey = readSecret /home/anon/.secrets/deepseek;
  openAiKey = readSecret /home/anon/.secrets/openai;
  elevenLabsKey = readSecret /home/anon/.secrets/elevenlabs;
  weatherKey = readSecret /home/anon/.secrets/weather;

  # Infrastructure
  pulumiToken = readSecret /home/anon/.secrets/pulumi;
  steamToken = readSecret /home/anon/.secrets/steam;
  homeIp = readSecret /home/anon/.secrets/home-ip;
  wireguardPrivateKey = readSecret /home/anon/.secrets/home-wireguard-private-key;
  wireguardPublicKey = readSecret /home/anon/.secrets/home-wireguard-public-key;
  wireguardEndpoint = readSecret /home/anon/.secrets/home-wireguard-endpoint;

  # AWS
  aws = readSecretJSON /home/anon/.secrets/aws.json;
}
