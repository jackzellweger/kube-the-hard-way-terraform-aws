#!/usr/bin/env bash

# Implements this spec: https://github.com/docker/docker-credential-helpers
# in order to aid in ECR login

set -eo pipefail


COMMAND="${1:-get}"
REGISTRY="$(</dev/stdin)"

function output() {
  echo "{\"Username\": \"AWS\", \"Secret\": \"$1\"}"
}

case "$REGISTRY" in
  795578270044.dkr.ecr.us-east-2.amazonaws.com)
    AWS_PROFILE=terraform-ops
    REGION=us-east-2
    ;;
  112168140497.dkr.ecr.us-east-2.amazonaws.com)
    AWS_PROFILE=terraform-dev
    REGION=us-east-2
    ;;
  *)
    >&2 echo "Unknown registry provided: $REGISTRY"
    exit 1
    ;;
esac

if [[ "$COMMAND" == "get" ]]; then
  PASSWORD="$(aws --profile "$AWS_PROFILE" --region "$REGION" ecr get-login-password)"
  output "$PASSWORD"
fi


