{ ... }:

{
  flake.modules.nixos.llama-cpp =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    let
      llama-cpp =
        (pkgs.llama-cpp.override {
          cudaSupport = config.nixpkgs.config.cudaSupport;
          rocmSupport = false;
          metalSupport = false;
          blasSupport = true;
        }).overrideAttrs
          (oldAttrs: {
            cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [ "-DGGML_NATIVE=ON" ];
            preConfigure = ''
              export NIX_ENFORCE_NO_NATIVE=0
              ${oldAttrs.preConfigure or ""}
            '';
          });

      port = 60000;
      idleSeconds = 300;
    in
    {
      networking.firewall.allowedTCPPorts = [ port ];

      systemd.services.llama-cpp = {
        description = "llama.cpp server";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment.LLAMA_CACHE = "/var/cache/llama-cpp";
        serviceConfig = {
          ExecStart = ''
            ${lib.getExe' llama-cpp "llama-server"} \
              --host 0.0.0.0 \
              --port ${toString port} \
              -hf mradermacher/Huihui-Qwen3.5-27B-abliterated-GGUF:Q4_K_M \
              --hf-file Huihui-Qwen3.5-27B-abliterated.Q4_K_M.gguf \
              -c 65536 \
              -fa on \
              -np 1 \
              --sleep-idle-seconds ${toString idleSeconds} \
              --no-webui
          '';
          CacheDirectory = "llama-cpp";
          Restart = "on-failure";
          RestartSec = 30;
        };
      };
    };

  flake.modules.homeManager.llama-cpp =
    { ... }:
    {
      programs.fish.shellAliases.local = "env ANTHROPIC_BASE_URL=http://localhost:60000 ANTHROPIC_API_KEY=not-needed ANTHROPIC_MODEL=qwen3.5-27b-abliterated ANTHROPIC_SMALL_FAST_MODEL=qwen3.5-27b-abliterated claude";

      programs.opencode.settings.provider.llama-cpp = {
        api = "openai";
        name = "llama.cpp (Local)";
        options = {
          baseURL = "http://192.168.11.254:60000/v1";
          apiKey = "not-needed";
        };
        models."qwen3.5-27b-abliterated" = {
          name = "Qwen3.5 27B Abliterated (Q4_K_M)";
          id = "qwen3.5-27b-abliterated";
          tool_call = true;
          temperature = true;
          reasoning = true;
          limit = {
            context = 65536;
            input = 65536;
            output = 16384;
          };
        };
      };
    };
}
