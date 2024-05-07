locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}


terraform {
  source = "../../../packages/terraform/infra_deployment"
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "us-east-2"
}
EOF
}

inputs = {

  // Bootstrapping params
  control_plane_instance_count = 1
  worker_instance_count = 1

  // Private key names
  private-key-filename = "ssh-private-key"

  // Script directory path
  scripts_dir_path = local.common_vars.inputs.scripts_dir_path_common

}
