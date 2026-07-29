{ ... }:

{
  flake.modules.homeManager.vm-curator =
    { pkgs, ... }:
    {
      home.packages = [
        (pkgs.callPackage ./_vm-curator.nix { })
        pkgs.qemu
      ];

      xdg.configFile."vm-curator/config.toml".text = ''
        # VM library location
        vm_library_path = "~/vm-space"

        # Default values for new VMs
        default_memory_mb = 4096
        default_cpu_cores = 2
        default_disk_size_gb = 64
        default_display = "gtk"      # gtk, sdl, spice-app, vnc
        default_enable_kvm = true

        # Behavior
        confirm_before_launch = true

        # Multi-GPU passthrough (Looking Glass)
        enable_multi_gpu_passthrough = false
        default_ivshmem_size_mb = 64
        show_gpu_warnings = true
        looking_glass_client_path = ""       # Path to Looking Glass client
        looking_glass_auto_launch = true     # Auto-launch client when VM starts

        # Single GPU passthrough
        single_gpu_enabled = false
        single_gpu_auto_tty = false          # Experimental: auto switch TTY
        single_gpu_dm_override = ""          # Override display manager detection
      '';
    };
}
