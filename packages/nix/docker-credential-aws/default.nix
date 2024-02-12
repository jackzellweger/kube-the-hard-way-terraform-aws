{ pkgs }: pkgs.writeShellScriptBin "docker-credential-aws" (builtins.readFile ./docker-credential-aws.sh)
