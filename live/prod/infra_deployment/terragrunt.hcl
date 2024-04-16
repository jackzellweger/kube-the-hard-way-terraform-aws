terraform {
  source = "../../../packages/terraform/infra_deployment"
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

# Configure inputs to the module
inputs = {

  // Bootstrapping params
  control_plane_instance_count = 2
  worker_instance_count = 2

  // Private key names
  private-key-filename = "ssh-private-key"

  // Script directory path
  scripts_dir_path = "${get_terragrunt_dir()}/../../../packages/scripts"
}
