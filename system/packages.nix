{ pkgs, unstable, config, system, zen-browser }:

let
  rustNightly = unstable.rust-bin.selectLatestNightlyWith (toolchain:
    toolchain.default.override {
      extensions = [
        "rust-src"
        "rustfmt"
        "clippy"
        "rust-analyzer"
      ];
    }
  );
in

with pkgs; [
  # Prettier rebuild
  nh
  
  # Browsers
  zen-browser.packages.${system}.default

  # Terminal & utilities
  alacritty
  btop
  helix
  ripgrep
  fd
  tree
  glib
  gsettings-desktop-schemas

  # LaTeX
  texlive.combined.scheme-medium
  zathura
  texlab
  tectonic

  # Wayland
  awww
  waybar

  # Audio
  pavucontrol
  pamixer

  # Brightness/media playing utilities
  brightnessctl
  playerctl

  # bluetooth
  bluetui

  # General development
  git
  gh
  python312
  uv
  nodejs_24
  bubblewrap
  cacert
  pkg-config
  glibc.bin
  perf

  # Rust
  rustNightly

  # C/C++/assembly
  gcc
  binutils
  nasm
  gnumake

  # CUDA
  cudaPackages.cuda_cudart
  cudaPackages.cuda_nvrtc
  cudaPackages.cuda_nvcc
  cudaPackages.cuda_cccl
  cudaPackages.cuda_cudart
]
