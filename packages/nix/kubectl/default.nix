# We pin kubectl to make sure our local clients are using a version that is compliant with the version of the Kubernetes API Server

# See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/networking/cluster/kubernetes/kubectl.nix for the build config
{ pkgs }:
pkgs.kubernetes.overrideAttrs (_: rec {
  pname = "kubectl";
  version = "1.25.15";
  
  src = pkgs.fetchFromGitHub {
    owner = "kubernetes";
    repo = "kubernetes";
    rev = "v${version}";
    hash = "sha256-TIuHXX7YCcsVU/oD6yxcT4wUfTw7KSvwhNf5Xtj738g=";
  };

  outputs = [ "out" "man" "convert" ];

  WHAT = pkgs.lib.concatStringsSep " " [
    "cmd/kubectl"
    "cmd/kubectl-convert"
  ];

  installPhase = ''
    runHook preInstall
    install -D _output/local/go/bin/kubectl -t $out/bin
    install -D _output/local/go/bin/kubectl-convert -t $convert/bin

    installManPage docs/man/man1/kubectl*

    installShellCompletion --cmd kubectl \
      --bash <($out/bin/kubectl completion bash) \
      --fish <($out/bin/kubectl completion fish) \
      --zsh <($out/bin/kubectl completion zsh)
    runHook postInstall
  '';

  meta = pkgs.kubernetes.meta // {
    description = "Kubernetes CLI";
    homepage = "https://github.com/kubernetes/kubectl";
    platforms = pkgs.lib.platforms.unix;
  };
})