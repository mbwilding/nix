{ ... }:

{
  flake.modules.nixos.llama =
    { lib, pkgs, ... }:

    let
      llama-cpp =
        (pkgs.llama-cpp.override {
          cudaSupport = true;
          rocmSupport = false;
          metalSupport = false;
          # Enable BLAS for optimized CPU layer performance (OpenBLAS)
          blasSupport = true;
        }).overrideAttrs
          (oldAttrs: rec {
            # version = "7205";
            # src = pkgs.fetchFromGitHub {
            #   owner = "ggml-org";
            #   repo = "llama.cpp";
            #   tag = "b${version}";
            #   hash = "sha256-1CcYbc8RWAPVz8hoxKEmbAgQesC1oGFZ3fhfuU5vmOc=";
            #   leaveDotGit = true;
            #   postFetch = ''
            #     git -C "$out" rev-parse --short HEAD > $out/COMMIT
            #     find "$out" -name .git -print0 | xargs -0 rm -rf
            #   '';
            # };

            # Enable native CPU optimizations (AVX, AVX2, etc.)
            cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
              "-DGGML_NATIVE=ON"
            ];

            # Disable Nix's march=native stripping
            preConfigure = ''
              export NIX_ENFORCE_NO_NATIVE=0
              ${oldAttrs.preConfigure or ""}
            '';
          });

      llama-server = lib.getExe' llama-cpp "llama-server";
    in
    {
      services = {
        # llama-cpp = {
        #   enable = true;
        #   package = llama-cpp;
        #   openFirewall = true;
        #   port = 11433;
        #   # model = "/data/services/models/moondream2/moondream2-text-model-f16.gguf";
        #   # extraFlags = [
        #   #   "--mmproj"
        #   #   "/data/services/models/moondream2/moondream2-mmproj-f16.gguf"
        #   #   "-ngl"
        #   #   "99"
        #   #   "-t"
        #   #   "12"
        #   #   "-tb"
        #   #   "12"
        #   # ];
        # };

        llama-swap = {
          enable = true;
          packages = pkgs.llama-swap;
          port = 60000;
          listenAddress = "0.0.0.0";
          openFirewall = true;
          settings = {
            healthCheckTimeout = 60;
            models = {
              "qwythos-9b" = {
                cmd = "${llama-server} --port \${PORT} -hf empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF:Q8_0 -ngl 99 -c 8192 --no-webui";
                aliases = [
                  "qwythos"
                  "mythos"
                ];
              };

              "qwythos-9b-fast" = {
                cmd = "${llama-server} --port \${PORT} -hf empero-ai/Qwythos-9B-Claude-Mythos-5-1M-GGUF:Q6_K -ngl 99 -c 8192 --no-webui";
                aliases = [
                  "qwythos-fast"
                  "mythos-fast"
                ];
              };

              # "other-model" = {
              #   proxy = "http://127.0.0.1:5555";
              #   cmd = "${llama-server} --port 5555 -m /var/lib/llama-cpp/models/other-model.gguf -ngl 0 -c 4096 -np 4 --no-webui";
              #   concurrencyLimit = 4;
              # };
            };
          };
        };
      };
    };
}
