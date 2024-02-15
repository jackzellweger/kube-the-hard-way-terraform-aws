{

# params
kube_public_address=$1

# Hostnames list should look like "10.240.0.10 10.240.0.11"
control_plane_node_hostnames_list=$(echo "$2" | tr ' ' ',') # will convert spaces to commas

# Built in from the source
KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "New York City",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "New York"
    }
  ]
}
EOF

echo
echo kubernetes public address
echo ${kube_public_address}
echo
echo control plane hostnames list:
echo ${control_plane_node_hostnames_list}
echo

cfssl gencert \
  -ca=ca.pem \
  -ca-key=ca-key.pem \
  -config=ca-config.json \
  -hostname=10.32.0.1,${control_plane_node_hostnames_list},${kube_public_address},127.0.0.1,${KUBERNETES_HOSTNAMES} \
  -profile=kubernetes \
  kubernetes-csr.json | cfssljson -bare kubernetes

}