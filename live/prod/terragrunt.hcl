locals {

    # The directory with all the scripts
    scripts_dir_path = "${get_terragrunt_dir()}/../../../packages/scripts"

}

# Include configuration to keep DRY
include {
  path = find_in_parent_folders()
}