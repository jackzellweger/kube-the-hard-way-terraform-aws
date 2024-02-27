{
  # vars
  worker_list=($1)
  elb_public_ip=$2

  #for instance in worker-0 worker-1 worker-2; do
  for ((i=0; i<${#worker_list[@]}; i++)); do
    kubectl config set-cluster kubernetes-the-hard-way \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://$2:6443 \
      --kubeconfig=${worker_list[i]}.kubeconfig

    kubectl config set-credentials system:node:${worker_list[i]} \
      --client-certificate=${worker_list[i]}.pem \
      --client-key=${worker_list[i]}-key.pem \
      --embed-certs=true \
      --kubeconfig=${worker_list[i]}.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way \
      --user=system:node:${worker_list[i]} \
      --kubeconfig=${worker_list[i]}.kubeconfig

    kubectl config use-context default --kubeconfig=${worker_list[i]}.kubeconfig
  done

}