{ pkgs }:

let
  cudaLdLibraryPath = pkgs.lib.makeLibraryPath [
    pkgs.stdenv.cc.cc.lib
    pkgs.cudaPackages.cuda_cudart
    pkgs.cudaPackages.cuda_nvrtc
    pkgs.cudaPackages.cuda_nvcc
  ];
in
{
  cudaShellHook = ''
    export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export NODE_EXTRA_CA_CERTS="$SSL_CERT_FILE"

    export CUDA_HOME="${pkgs.cudaPackages.cuda_nvcc}"
    export CUDA_PATH="${pkgs.cudaPackages.cuda_nvcc}"

    export UV_CACHE_DIR="$PWD/.uv-cache"
    export UV_PYTHON_INSTALL_DIR="$PWD/.uv-python"

    CUDA_SHIM_DIR="$PWD/.cuda-shim"
    mkdir -p "$CUDA_SHIM_DIR"

    if [ -e /run/opengl-driver/lib/libcuda.so.1 ]; then
      ln -sf /run/opengl-driver/lib/libcuda.so.1 "$CUDA_SHIM_DIR/libcuda.so.1"
      ln -sf /run/opengl-driver/lib/libcuda.so.1 "$CUDA_SHIM_DIR/libcuda.so"
      export TRITON_LIBCUDA_PATH="$CUDA_SHIM_DIR"
    elif [ -e /run/opengl-driver-32/lib/libcuda.so.1 ]; then
      ln -sf /run/opengl-driver-32/lib/libcuda.so.1 "$CUDA_SHIM_DIR/libcuda.so.1"
      ln -sf /run/opengl-driver-32/lib/libcuda.so.1 "$CUDA_SHIM_DIR/libcuda.so"
      export TRITON_LIBCUDA_PATH="$CUDA_SHIM_DIR"
    fi

    export LD_LIBRARY_PATH="$CUDA_SHIM_DIR:${cudaLdLibraryPath}''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  '';

  cudaBwrapSetup = workspacePath: ''
    CUDA_SHIM_ROOT="$ROOT/.cuda-shim"
    CUDA_SHIM_SANDBOX="${workspacePath}/.cuda-shim"
    mkdir -p "$CUDA_SHIM_ROOT"

    if [ -e /run/opengl-driver/lib/libcuda.so.1 ]; then
      ln -sf /run/opengl-driver/lib/libcuda.so.1 "$CUDA_SHIM_ROOT/libcuda.so.1"
      ln -sf /run/opengl-driver/lib/libcuda.so.1 "$CUDA_SHIM_ROOT/libcuda.so"
      args+=("--setenv" "TRITON_LIBCUDA_PATH" "$CUDA_SHIM_SANDBOX")
    elif [ -e /run/opengl-driver-32/lib/libcuda.so.1 ]; then
      ln -sf /run/opengl-driver-32/lib/libcuda.so.1 "$CUDA_SHIM_ROOT/libcuda.so.1"
      ln -sf /run/opengl-driver-32/lib/libcuda.so.1 "$CUDA_SHIM_ROOT/libcuda.so"
      args+=("--setenv" "TRITON_LIBCUDA_PATH" "$CUDA_SHIM_SANDBOX")
    fi

    args+=("--setenv" "CUDA_HOME" "${pkgs.cudaPackages.cuda_nvcc}")
    args+=("--setenv" "CUDA_PATH" "${pkgs.cudaPackages.cuda_nvcc}")
    args+=("--setenv" "LD_LIBRARY_PATH" "$CUDA_SHIM_SANDBOX:${cudaLdLibraryPath}")

    args+=("--setenv" "CUDA_DEVICE_ORDER" "PCI_BUS_ID")
    args+=("--setenv" "NVIDIA_VISIBLE_DEVICES" "all")
    args+=("--setenv" "NVIDIA_DRIVER_CAPABILITIES" "compute,utility")
  '';
}
