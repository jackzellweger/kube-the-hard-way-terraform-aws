// Generate configuration for data and control plane encryption at-rest
resource "null_resource" "generate_config_encryption" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kubeconfig_adminuser
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/data-encryption.sh" // TODO: Contains kube manifest
  }

}

// Distribute certs & kubeconfig to workers
resource "null_resource" "distribute_certs_kubeconfig_worker" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    aws_instance.kubernetes_worker_instances,
    null_resource.generate_config_encryption
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/distribute-certs-kubeconfig-worker.sh \"${join(" ", [for instance in aws_instance.kubernetes_worker_instances : instance.tags["Name"]])}\" ${var.private-key-filename} ubuntu \"${join(" ", aws_eip.worker_eip.*.public_ip)}\""
  }

}

// Distribute certs, kubeconfig, and encryption configuration to controllers
resource "null_resource" "distribute_certs_kubeconfig_controller" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    aws_instance.kubernetes_control_plane_instances,
    null_resource.distribute_certs_kubeconfig_worker
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/distribute-certs-kubeconfig-controller.sh \"${join(" ", [for instance in aws_instance.kubernetes_control_plane_instances : instance.tags["Name"]])}\" ${var.private-key-filename} ubuntu \"${join(" ", aws_eip.control_plane_eip.*.public_ip)}\""
  }

}

// Bootstrap etcd and control plane on controllers
resource "terraform_data" "controller_bootstrap" {
  
  // Count
  count = var.control_plane_instance_count

  // Re-runs every time we deploy
  triggers_replace = "${timestamp()}"
  depends_on = [ null_resource.distribute_certs_kubeconfig_controller ]


  connection {
    type = "ssh"
    host = aws_eip.control_plane_eip[count.index].public_ip
    user = "ubuntu"
    private_key = file("${var.private-key-filename}.pem")
  }

  provisioner "remote-exec" {
    inline = [ // TODO: Contains kube manifest
      "${templatefile("../../scripts/bootstrap-controllers.sh.tftpl", { controller_private_ip = "10.240.0.1${count.index}", controller_hostname = "controller-${count.index}", controller_public_address = aws_eip.kubernetes_the_hard_way.public_ip }) }"
     ]
  }
  
}

// Resume at 'RBAC for Kubelet Authorization'
resource "terraform_data" "controller_kubelet_rbac_auth" {
  
  // Only need to run on one controller, we will choose controller-0
  // count = var.control_plane_instance_count

  // Re-runs every time we deploy
  triggers_replace = "${timestamp()}"
  depends_on = [ terraform_data.controller_bootstrap ]


  connection {
    type = "ssh"
    host = aws_eip.control_plane_eip[0].public_ip // Only need ip of controller-0
    user = "ubuntu"
    private_key = file("${var.private-key-filename}.pem")
  }

  provisioner "remote-exec" {
    script = "../../scripts/kubelet-rbac-auth.sh" // TODO: Contains kube manifest
  }
  
}