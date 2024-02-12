{ pkgs }: pkgs.writeShellScriptBin "enter-shell-local" (builtins.readFile ./enter-shell-local.sh)
