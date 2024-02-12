# We pin Tilt since there were some missing assets in release 0.33.6 making it a broken release and we don't want to inadvertantly install it

# See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/networking/cluster/tilt/default.nix for the build config
{ pkgs }: 
pkgs.tilt.overrideAttrs (_: rec {
  version = "0.33.4";

  src = pkgs.fetchFromGitHub {
    owner = "tilt-dev";
    repo = "tilt";
    rev = "v${version}";
    hash = "sha256-rQ5g5QyGyuJAHmE8zGFzqtpqW2xEju5JV386y9Cn+cs=";
  };
})