{ lib, pkgs, ... }:

let
  llama-cpp =
    (pkgs.llama-cpp.override {
      cudaSupport = true;
      rocmSupport = false;
      metalSupport = false;
      blasSupport = true;
    }).overrideAttrs
      (oldAttrs: {
        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
          "-DGGML_NATIVE=ON"
        ];

        preConfigure = ''
          export NIX_ENFORCE_NO_NATIVE=0
          ${oldAttrs.preConfigure or ""}
        '';
      });

  llama-server = lib.getExe' llama-cpp "llama-server";

  mkModel =
    {
      name,
      port,
      quant,
      file,
      aliases ? [ ],
      repo ? "empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF",
      ctx ? 1048576,
      ngl ? 99,
      ttl ? 300,
      extraArgs ? "",
    }:
    lib.nameValuePair name {
      proxy = "http://127.0.0.1:${toString port}";
      inherit ttl aliases;

      cmd = ''
        ${llama-server} \
          --port ${toString port} \
          -hf ${repo}:${quant} \
          --hf-file ${file} \
          -ngl ${toString ngl} \
          -c ${toString ctx} \
          --no-webui \
          ${extraArgs}
      '';
    };

in
{
  services.llama-swap = {
    enable = true;
    package = pkgs.llama-swap;

    port = 60000;
    listenAddress = "0.0.0.0";
    openFirewall = true;

    settings = {
      healthCheckTimeout = 60;

      models = lib.listToAttrs [
        (mkModel {
          name = "qwythos-9b";
          port = 61001;
          repo = "empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF";
          quant = "Q8_0";
          file = "Qwythos-9B-Claude-Mythos-5-1M-Q8_0.gguf";
          aliases = [
            "qwythos"
            "mythos"
          ];
        })

        (mkModel {
          name = "qwythos-9b-fast";
          port = 61002;
          repo = "empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF";
          quant = "Q6_K";
          file = "Qwythos-9B-Claude-Mythos-5-1M-Q6_K.gguf";
          aliases = [
            "qwythos-fast"
            "mythos-fast"
          ];
        })
      ];
    };
  };

  systemd.services.llama-swap.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "mbwilding";
    Group = "users";
    ProtectHome = lib.mkForce false;
  };
}
