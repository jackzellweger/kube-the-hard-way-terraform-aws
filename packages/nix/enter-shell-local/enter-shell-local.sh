#!/usr/bin/env bash

set -eo pipefail

# This script is meant to be sourced inside the enterShell
# parameter of our devenv.nix

>&2 echo "entering local shell"

#############################################
## Kubernetes
#############################################

# Use repo-local kubeconfig file
export KUBECONFIG="$DEVENV_ROOT/.kube/config"
export KUBE_CONFIG_PATH="$DEVENV_ROOT/.kube/config"

kubectl config use-context terraform-dev-ue2 

#############################################
## AWS
#############################################

# Use repo-local AWS settings
export AWS_SHARED_CREDENTIALS_FILE="$DEVENV_ROOT/.aws/credentials"
export AWS_CONFIG_FILE="$DEVENV_ROOT/.aws/config"
export AWS_PROFILE=terraform-dev

#############################################
## Terraform
#############################################

# Use repo-local terragrunt downloads
export TERRAGRUNT_DOWNLOAD="$DEVENV_ROOT/.terragrunt-cache"

#############################################
## Podman / Docker
#############################################

# Needed in order to use non-root podman with docker emulation
export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
export DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock
export DOCKER_SOCK=$XDG_RUNTIME_DIR/podman/podman.sock

# We provide a custom credential helper so we can avoid
# the nuisance of the ECR login flow
export REGISTRY_AUTH_FILE="$DEVENV_ROOT/.podman/config.json"
export DOCKER_CONFIG="$DEVENV_ROOT/.podman" # Needed for buildkit to work