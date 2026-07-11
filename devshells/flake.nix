{
  description = "Reusable development shells";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    cudaEnv = import ./cuda-env.nix {
      inherit pkgs;
    };

    mkClaudeSandbox = import ./claude-sandbox.nix {
      inherit pkgs cudaEnv;
    };

    mkProject =
      {
        name,
        claude ? false,
        extraPackages ? _: [ ],
        extraShellHook ? "",
      }:

      let
        shell = pkgs.mkShell {
          inherit name;

          packages = extraPackages pkgs;

          shellHook = ''
            ${cudaEnv.cudaShellHook}

            _nix_dev_find_root() {
              local d
              d="$(pwd -P)"

              while [ "$d" != "/" ]; do
                if [ -f "$d/flake.nix" ]; then
                  printf "%s\n" "$d"
                  return
                fi

                d="$(dirname "$d")"
              done

              pwd -P
            }

            export NIX_DEV_NAME="${name}"
            export NIX_DEV_ROOT="$(_nix_dev_find_root)"

            _nix_dev_prompt_path() {
              local p rel
              p="$(pwd -P)"

              case "$p" in
                "$NIX_DEV_ROOT")
                  return
                  ;;
                "$NIX_DEV_ROOT"/*)
                  rel="''${p#"$NIX_DEV_ROOT"/}"
                  ;;
                *)
                  rel="$p"
                  ;;
              esac

              if [ -n "$rel" ]; then
                printf "%s " "$rel"
              fi
            }

            if [ -n "''${ZSH_VERSION:-}" ]; then
              autoload -Uz colors && colors
              setopt PROMPT_SUBST
              PROMPT='%F{green}[${name}]%f %F{blue}$(_nix_dev_prompt_path)%f%Bλ%b '
            elif [ -n "''${BASH_VERSION:-}" ]; then
              _nix_dev_set_bash_prompt() {
                local path
                path="$(_nix_dev_prompt_path)"
                PS1="\[\e[32m\][${name}]\[\e[0m\] \[\e[34m\]$path\[\e[0m\]\[\e[1m\]λ\[\e[0m\] "
              }

              PROMPT_COMMAND="_nix_dev_set_bash_prompt''${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
            fi

            ${extraShellHook}

            echo
            echo "${name} ready."
            echo "flake root: $NIX_DEV_ROOT"
            echo "TRITON_LIBCUDA_PATH=''${TRITON_LIBCUDA_PATH:-<unset>}"
            echo
          '';
        };
      in
      {
        devShell = shell;

        packages =
          if claude then {
            claude-sandbox = mkClaudeSandbox {
              inherit name;
            };
          } else { };
      };
  in
  {
    lib.${system}.mkProject = mkProject;

    devShells.${system}.default =
      (mkProject { name = "python-cuda"; }).devShell;
  };
}
