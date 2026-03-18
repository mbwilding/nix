{ ... }:

{
  programs = {
    k9s = {
      enable = true;
      settings = {
        k9s = {
          apiServerTimeout = "15s";
          defaultView = "";
          disablePodCounting = false;
          keepMissingClusters = false;
          liveViewAutoRefresh = false;
          maxConnRetry = 15;
          noExitOnCtrlC = false;
          noIcons = false;
          portForwardAddress = "localhost";
          readOnly = false;
          refreshRate = 2;
          screenDumpDir = "/tmp/k9s";
          skipLatestRevCheck = true;
          logger = {
            tail = 100;
            buffer = 5000;
            sinceSeconds = -1;
            fullScreen = true;
            textWrap = true;
            showTime = true;
          };
          shellPod = {
            image = "busybox";
            namespace = "default";
            limits = {
              cpu = "100m";
              memory = "100Mi";
            };
            tty = true;
          };
          thresholds = {
            cpu = {
              critical = 90;
              warn = 70;
            };
            memory = {
              critical = 90;
              warn = 70;
            };
          };
          ui = {
            enableMouse = false;
            # Hide header
            headless = false;
            logoless = true;
            crumbsless = false;
            # Toggles reactive UI. This option provide for watching on disk artifacts changes and update the UI live  Defaults to false.
            reactive = false;
            noIcons = false;
          };
        };
      };
      views = {
        "v1/pods" = {
          columns = [
            "NAMESPACE"
            "NAME"
            "SQUAD:.metadata.labels.squad"
            "STATUS"
            "READY"
            "AGE"
            "IP"
            "NODE"
          ];
        };
      };
    };
  };
}
