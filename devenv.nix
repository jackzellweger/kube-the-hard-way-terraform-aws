{ pkgs, config, inputs, ... }:
let

  customModule = module: import ./packages/nix/${module} { pkgs = pkgs; };

  common_packages = with pkgs; [

    # Versioning
    git     # vcs CLI
    git-lfs # stores binary files in git host

    # Github
    gh # github cli

    # Kubernetes
    (customModule "kubectl") # declarative iac tool
    cfssl                    # certificates

    # AWS
    awscli2  # aws CLI
    aws-nuke # nukes resources in aws accounts

    # IaC
    terraform  # IaC
    terragrunt # terraform-runner
  ];

in
{
  enterShell = ''
    unset PYTHONPATH # fix for the issue posted here https://github.com/cachix/devenv/pull/745#issuecomment-1701526176

    ${(if config.env.CI == "true" then "" else "source enter-shell-local")}
  '';

  packages = common_packages;

}
