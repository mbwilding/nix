{
  home ? builtins.getEnv "HOME",
}:

let
  readSecret =
    path:
    if builtins.pathExists path then builtins.readFile path else throw "Secret file not found: ${path}";

  readSecretJSON = path: builtins.fromJSON (readSecret path);
in
{
  # SSH keys
  personalPublicKey = readSecret "${home}/.ssh/personal.pub";
  workPublicKey = readSecret "${home}/.ssh/work.pub";

  # Work identity
  workName = readSecret "${home}/.secrets/work-name";
  workId = readSecret "${home}/.secrets/work-id";
  workEmailName = readSecret "${home}/.secrets/work-email-name";
  workEmailId = readSecret "${home}/.secrets/work-email-id";

  # GitHub
  githubWorkUsername = readSecret "${home}/.secrets/github-work-username";
  githubWorkToken = readSecret "${home}/.secrets/github-work";
  githubPersonalToken = readSecret "${home}/.secrets/github-personal";

  # GitLab
  gitlabWorkToken = readSecret "${home}/.secrets/gitlab-work";

  # Cargo
  cargoToken = readSecret "${home}/.secrets/cargo";

  # API keys
  anthropicKey = readSecret "${home}/.secrets/anthropic";
  deepSeekKey = readSecret "${home}/.secrets/deepseek";
  openAiKey = readSecret "${home}/.secrets/openai";
  elevenLabsKey = readSecret "${home}/.secrets/elevenlabs";
  weatherKey = readSecret "${home}/.secrets/weather";

  # Networks
  wifiHomeSsid = readSecret "${home}/.secrets/wifi-home-ssid";
  wifiHomePassword = readSecret "${home}/.secrets/wifi-home-password";
  wifiParentsSsid = readSecret "${home}/.secrets/wifi-parents-ssid";
  wifiParentsPassword = readSecret "${home}/.secrets/wifi-parents-password";

  # Vault
  password = readSecret "${home}/.secrets/password";

  # Infrastructure
  pulumiToken = readSecret "${home}/.secrets/pulumi";
  steamToken = readSecret "${home}/.secrets/steam";
  homeIp = readSecret "${home}/.secrets/home-ip";
  wireguardPrivateKey = readSecret "${home}/.secrets/home-wireguard-private-key";
  wireguardPublicKey = readSecret "${home}/.secrets/home-wireguard-public-key";
  wireguardEndpoint = readSecret "${home}/.secrets/home-wireguard-endpoint";

  # AWS
  aws = readSecretJSON "${home}/.secrets/aws.json";
}
