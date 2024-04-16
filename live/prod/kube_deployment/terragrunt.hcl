terraform {
  source = "../../../packages/terraform/kube_deployment"
}

# Indicate what region to deploy the resources into
generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "us-east-2"
}
EOF
}

dependencies {
    paths = ["../infra_deployment"]
}


# Configure inputs to the module
inputs = {

  // TODO: Any input vars we want here? Kubeconfig?
}