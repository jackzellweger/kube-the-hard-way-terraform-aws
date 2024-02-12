{ pkgs }:
let

  version = "2.16.10";
  src = 
    if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
      pkgs.fetchurl {
        urls = [
          "https://developer.salesforce.com/media/salesforce-cli/sf/versions/2.16.10/38f3e4f/sf-v2.16.10-38f3e4f-linux-x64.tar.xz"
        ];
        sha256 = "7d751e5f1deb6c41ba75f3e7bf92910f77a42050d3659902dae032aaa84e89f5";
      }
    else if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then 
      pkgs.fetchurl {
        urls = [
          "https://developer.salesforce.com/media/salesforce-cli/sf/versions/2.16.10/38f3e4f/sf-v2.16.10-38f3e4f-darwin-arm64.tar.xz"
        ];
        sha256 = "8efc319b5e6be709eda948049f674f9362a7432cae5d53142a76629a79069936";
      }
    else
      throw "SF CLI not supported for ${pkgs.stdenv.hostPlatform.system}";

in pkgs.stdenv.mkDerivation {

  pname = "SFCLI";
  inherit version;

  inherit src;

  dontUnpack = true;
  installPhase = ''
    mkdir -p $out
    tar xJf $src -C $out --strip-components 1
  '';

  meta = with pkgs.lib; {
    description = "Salesforce CLI";
    homepage = "https://www.salesforce.com/";
    platforms = [ "x86_64-linux" "aarch64-darwin" ];
  };
}