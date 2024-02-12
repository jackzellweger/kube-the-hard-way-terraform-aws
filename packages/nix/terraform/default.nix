# We pin terraform since changes in versions could cause destructive impact to the
# the infrastrcuture

# See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/networking/cluster/terraform/default.nix#L54
# for the build config
{ pkgs }:
pkgs.mkTerraform {
  version = "1.4.6";
  hash = "sha256-V5sI8xmGASBZrPFtsnnfMEHapjz4BH3hvl0+DGjUSxQ=";
  vendorHash = "sha256-OW/aS6aBoHABxfdjDxMJEdHwLuHHtPR2YVW4l0sHPjE=";
}
