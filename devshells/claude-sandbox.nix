{ pkgs, cudaEnv }:

{
  name,
  packageName ? "claude-sandbox",
  extraRuntimeInputs ? _: [ ],
}:

let
  workspacePath = "/" + name;

  runtimeInputs = with pkgs; [
    bubblewrap
    nodejs_20
    python312
    uv
    git
    ripgrep
    fd
    cacert
    gcc
    binutils
    pkg-config
    coreutils
    gnugrep
    gnused
    findutils
    bash
    glibc.bin
  ] ++ extraRuntimeInputs pkgs;

  sandboxPath = pkgs.lib.makeBinPath runtimeInputs;
in

pkgs.writeShellApplication {
  name = packageName;

  inherit runtimeInputs;

  text = ''
    set -euo pipefail

    ROOT="$(pwd -P)"
    WORKSPACE="${workspacePath}"

    CLAUDE_HOME="$ROOT/.claude-home"
    UV_CACHE="$ROOT/.uv-cache"
    UV_PYTHON="$ROOT/.uv-python"
    VENV_DIR="$ROOT/.venv"

    if [ ! -f "$ROOT/package.json" ]; then
      echo "Missing package.json."
      echo "Run:"
      echo "  nix develop"
      echo "  npm init -y"
      echo "  npm i -D @anthropic-ai/claude-code"
      exit 1
    fi

    CLI_JS="$ROOT/node_modules/@anthropic-ai/claude-code/cli.js"
    if [ ! -f "$CLI_JS" ]; then
      echo "Missing $CLI_JS."
      echo "Run:"
      echo "  nix develop"
      echo "  npm i -D @anthropic-ai/claude-code"
      exit 1
    fi

    mkdir -p \
      "$CLAUDE_HOME" \
      "$CLAUDE_HOME/.config" \
      "$CLAUDE_HOME/.cache" \
      "$CLAUDE_HOME/.local/state" \
      "$UV_CACHE" \
      "$UV_PYTHON" \
      "$VENV_DIR"

    if [ ! -x "$VENV_DIR/bin/python" ]; then
      echo "Missing project virtualenv at $VENV_DIR."
      echo "Run:"
      echo "  nix develop"
      echo "  uv venv --python 3.12"
      echo "  source .venv/bin/activate"
      echo "  uv sync"
      exit 1
    fi

    args=()
    args+=(--unshare-all)
    args+=(--share-net)
    args+=(--die-with-parent)
    args+=(--new-session)

    args+=(--proc /proc)
    args+=(--dev /dev)
    args+=(--tmpfs /tmp)

    args+=(--dir /sbin)
    args+=(--ro-bind ${pkgs.glibc.bin}/bin/ldconfig /sbin/ldconfig)
    args+=(--ro-bind /nix /nix)

    [ -f /etc/resolv.conf ] && args+=(--ro-bind /etc/resolv.conf /etc/resolv.conf)
    [ -f /etc/hosts ] && args+=(--ro-bind /etc/hosts /etc/hosts)
    [ -f /etc/services ] && args+=(--ro-bind /etc/services /etc/services)

    args+=(--ro-bind ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-bundle.crt)
    args+=("--setenv" "SSL_CERT_FILE" "/etc/ssl/certs/ca-bundle.crt")
    args+=("--setenv" "NODE_EXTRA_CA_CERTS" "/etc/ssl/certs/ca-bundle.crt")

    args+=(--bind "$ROOT" "$WORKSPACE")

    [ -f "$ROOT/flake.nix" ] && args+=(--ro-bind "$ROOT/flake.nix" "$WORKSPACE/flake.nix")
    [ -f "$ROOT/flake.lock" ] && args+=(--ro-bind "$ROOT/flake.lock" "$WORKSPACE/flake.lock")

    args+=("--setenv" "HOME" "$WORKSPACE/.claude-home")
    args+=("--setenv" "USER" "sandbox")
    args+=("--setenv" "LOGNAME" "sandbox")
    args+=("--setenv" "XDG_CONFIG_HOME" "$WORKSPACE/.claude-home/.config")
    args+=("--setenv" "XDG_CACHE_HOME" "$WORKSPACE/.claude-home/.cache")
    args+=("--setenv" "XDG_STATE_HOME" "$WORKSPACE/.claude-home/.local/state")

    args+=("--setenv" "UV_CACHE_DIR" "$WORKSPACE/.uv-cache")
    args+=("--setenv" "UV_PYTHON_INSTALL_DIR" "$WORKSPACE/.uv-python")
    args+=("--setenv" "VIRTUAL_ENV" "$WORKSPACE/.venv")
    args+=("--setenv" "PYTHONNOUSERSITE" "1")

    for dev in \
      /dev/nvidiactl \
      /dev/nvidia-uvm \
      /dev/nvidia-uvm-tools \
      /dev/nvidia-modeset \
      /dev/nvidia[0-9]*
    do
      [ -e "$dev" ] && args+=(--dev-bind "$dev" "$dev")
    done

    [ -d /dev/dri ] && args+=(--dev-bind /dev/dri /dev/dri)
    [ -d /run/opengl-driver ] && args+=(--ro-bind /run/opengl-driver /run/opengl-driver)
    [ -d /run/opengl-driver-32 ] && args+=(--ro-bind /run/opengl-driver-32 /run/opengl-driver-32)
    [ -d /sys ] && args+=(--ro-bind /sys /sys)

    ${cudaEnv.cudaBwrapSetup workspacePath}

    args+=("--setenv" "PATH" "$WORKSPACE/.venv/bin:${sandboxPath}")
    args+=(--chdir "$WORKSPACE")

    exec ${pkgs.bubblewrap}/bin/bwrap "''${args[@]}" \
      ${pkgs.nodejs_20}/bin/node \
      "$WORKSPACE/node_modules/@anthropic-ai/claude-code/cli.js" \
      "$@"
  '';
}
