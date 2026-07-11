{ config, pkgs, unstable, system, zen-browser, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "k10temp" ];
  boot.kernel.sysctl = {
    "kernel.perf_event_paranoid" = -1;
    "kernel.kptr_restrict" = 0;
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Los_Angeles";

  nixpkgs.config.allowUnfree = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.udev.packages = [ config.hardware.nvidia.package ];

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    nvidiaPersistenced = true;
    open = true;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };

  boot.blacklistedKernelModules = [ "nouveau" ];
  boot.kernelParams = [ "nvidia_drm.modeset=1" ];

  systemd.services.nvidia-persistenced = {
    after = [ "systemd-modules-load.service" ];
    wants = [ "systemd-modules-load.service" ];
    unitConfig = {
      ConditionPathExists = "/dev/nvidia0";
    };
  };

  security.rtkit.enable = true;

  services.xserver.enable = false;
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    wireplumber.enable = true;

    wireplumber.extraConfig.bluetooth = {
      "monitor.bluez.properties" = {
        "bluez5.roles" = [ "a2dp_sink" "a2dp_source" ];
        "bluez5.codecs" = [ "sbc" "sbc_xq" "aac" ];
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-hw-volume" = true;
      };
    };
  };

  services.pulseaudio.enable = false;

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;

  services.greetd.enable = true;
  services.greetd.settings.default_session = {
    command = "Hyprland";
    user = "zach";
  };

  services.seatd.enable = true;

  services.printing.enable = true;

  programs.zsh.enable = true;

  users.users.zach = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "networkmanager" ];
    shell = pkgs.zsh;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.sessionVariables = {
    XDG_DATA_DIRS = [
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];
  };

  environment.systemPackages = import ./packages.nix {
    inherit pkgs unstable config system zen-browser;
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerd-fonts.atkynson-mono
  ];

  fonts.fontconfig = {
    defaultFonts = {
      monospace = [ "AtkynsonMono Nerd Font Mono" ];
    };
  };

  system.stateVersion = "25.05";
}
