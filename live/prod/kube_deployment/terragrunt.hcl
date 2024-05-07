locals {
  common_vars = read_terragrunt_config(find_in_parent_folders("common.hcl"))
}

terraform {
  source = "../../../packages/terraform/kube_deployment"
}

generate "provider" {
  path = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents = <<EOF
provider "aws" {
  region = "us-east-2"
}

provider "kubernetes" {
  config_path    = var.kube_config_path
  load_config_file = true 
}
EOF
}


dependencies {
    paths = ["../infra_deployment"]
}


inputs = {

  // Script directory path
  scripts_dir_path = local.common_vars.inputs.scripts_dir_path_common

  // TODO: Path to kubeconfig?
  kube_config_path = "./path/to/kubeconfig"

}