// ----- Providers

provider "aws" {
  region = "us-east-2"
}

// ----- Variables

variable "private-key-filename" {
  type = string
  default = "ssh-private-key"
}

variable "control_plane_instance_count" {
  type = number
  default = 2
}

variable "worker_instance_count" {
  type = number
  default = 2
}

// ----- Resources

// Our VPC
resource "aws_vpc" "kubernetes-the-hard-way" {

  tags = {
    Name = "kubernetes-the-hard-way"
  }

  cidr_block = "10.240.0.0/24"
}

// Our subnet attached to our VPC
resource "aws_subnet" "kubernetes" {
  vpc_id = aws_vpc.kubernetes-the-hard-way.id
  cidr_block = "10.240.0.0/24"
}

// Gateway
resource "aws_internet_gateway" "kubernetes_gateway" {
  vpc_id = aws_vpc.kubernetes-the-hard-way.id

  tags = {
    Name = "kubernetes-the-hard-way-gateway"
  }
}

// Route table for the VPC
resource "aws_route_table" "kubernetes_route_table" {
  vpc_id = aws_vpc.kubernetes-the-hard-way.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubernetes_gateway.id
  }

  tags = {
    Name = "kubernetes-the-hard-way-route-table"
  }
}

// Route table vpc subnet association
resource "aws_route_table_association" "kubernetes_subnet_association" {
  subnet_id      = aws_subnet.kubernetes.id
  route_table_id = aws_route_table.kubernetes_route_table.id
}


// Security group that defines our VPC's ingress/egress rules
resource "aws_security_group" "vpc_security_group" {
  // GCloud Command:
  // gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
  // --allow tcp,udp,icmp \
  // --network kubernetes-the-hard-way \
  // --source-ranges 10.240.0.0/24,10.200.0.0/16

  name        = "vpc_security_group"
  description = "Allow all TCP, UDP, and ICMP inbound and outbound traffic"
  tags = {
    Name = "vpc_security_group"
  }

  vpc_id = aws_vpc.kubernetes-the-hard-way.id

  // Allow internal TCP ingress
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.kubernetes-the-hard-way.cidr_block, "10.200.0.0/16"]
  }

  // Allow internal UDP ingress
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [aws_vpc.kubernetes-the-hard-way.cidr_block, "10.200.0.0/16"]
  }

  // Allow internal ICMP ingress
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.kubernetes-the-hard-way.cidr_block, "10.200.0.0/16"]
  }

  // Allow internal TCP egress
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.kubernetes-the-hard-way.cidr_block, "10.200.0.0/16"]
  }

  // Allow internal UDP egress
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = [aws_vpc.kubernetes-the-hard-way.cidr_block, "10.200.0.0/16"]
  }

  // Allow internal ICMP egress
  egress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [aws_vpc.kubernetes-the-hard-way.cidr_block, "10.200.0.0/16"]
  }

  // Allow external SSH ingress
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow external Kubernetes Server ingress
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow external ICMP (ping)
  ingress {
    from_port   = -1 
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // Allow all outbound traffic
  // TODO: Fix this, make it less looose
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

// TODO: Uncomment when we have more IPs available
// TODO: Is this domain = vpc?
// Static IP for our load balancer
// TODO: Do we need to create a gateway and associate this with it?
// Let's wait and see
resource "aws_eip" "kubernetes_the_hard_way" {

  // GCloud Command:
  // gcloud compute addresses create kubernetes-the-hard-way \
  // --region $(gcloud config get-value compute/region)

  tags = {
    Name = "kubernetes_the_hard_way"
  }

  domain = "vpc"

}


// Control Plane nodes
resource "aws_instance" "kubernetes_control_plane_instances" {

  depends_on = [ tls_private_key.worker_ssh_private_key, aws_key_pair.generated_key ]
  
  count = var.control_plane_instance_count
  
  tags = {
    Name = "controller-${count.index}"
    Project = "kubernetes-the-hard-way"
    InstanceType = "controller"
  }

  ami = "ami-05fb0b8c1424f266b" // Ubuntu Server 20.04
  instance_type = "t2.medium"

  key_name = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.vpc_security_group.id]
  subnet_id = aws_subnet.kubernetes.id
  private_ip = "10.240.0.1${count.index}"
  
  root_block_device {
    volume_size = 20 // In GB
  }

  source_dest_check = false // IP forwarding, 'false' is enabled
  iam_instance_profile = aws_iam_instance_profile.control_plane_instance_profile.name

  // TODO: Make it so this executes after cert creation
  // Could use this: <https://stackoverflow.com/questions/14692353/executing-a-bash-script-upon-file-creation>
  /*
  user_data = <<-MULTILINE
              #!/bin/bash
              ${templatefile("../../scripts/user-data-etcd.sh.tftpl", { controller_private_ip = "10.240.0.1${count.index}", controller_hostname = "controller-${count.index}" }) }
              MULTILINE
  */
}

// EIPs for contol plane nodes
resource "aws_eip" "control_plane_eip" {
  count    = var.control_plane_instance_count
  domain      = "vpc"
  depends_on = [ aws_instance.kubernetes_control_plane_instances ]
}

// EIP-instance association for control plane nodes
resource "aws_eip_association" "control_plane_eip_assoc" {
  count    = var.control_plane_instance_count

  instance_id   = aws_instance.kubernetes_control_plane_instances[count.index].id
  allocation_id = aws_eip.control_plane_eip[count.index].id
}

// Control plane node profile
resource "aws_iam_instance_profile" "control_plane_instance_profile" {
  name = "control-plane-instance-profile"
  role = aws_iam_role.control-plane-node-service-role.name
}

// The attachment of the policy for the control plane node to the role associate with the control plane node
resource "aws_iam_role_policy_attachment" "control-plane-policy-attachment" {
  role       = aws_iam_role.control-plane-node-service-role.name
  policy_arn = aws_iam_policy.control-plane-policy.arn
}

// Service Role for control plane node
resource "aws_iam_role" "control-plane-node-service-role" {
  name = "control-plane-node-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy-ec2.json
}

// The policy we will attach to the service role that our control plane will have
resource "aws_iam_policy" "control-plane-policy" {
  name        = "control-plane-policy"
  description = "A policy that grants permissions to the Kube control plane equivalent to GCP scopes"
  policy      = data.aws_iam_policy_document.policy-doc-for-control-plane-node.json
}

// Policy document we attach to our policy (GCloud 'scopes' equiv)
data "aws_iam_policy_document" "policy-doc-for-control-plane-node" {

  // GCloud Command:
  // --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring --subnet kubernetes

  // EC2 Full Access
  statement {
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  // S3 Read-Only Access
  statement {
    actions   = ["s3:Get*", "s3:List*"]
    resources = ["arn:aws:s3:::*"]
  }

  // CloudWatch Full Access
  statement {
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }

  // CloudWatch Logs Write Access
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
  
}

// Assume Role Policy Document, any EC2 can assume this role
data "aws_iam_policy_document" "assume-role-policy-ec2" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"] // Assuming this role is for an EC2 instance
    }
  }
}

// Worker nodes
resource "aws_instance" "kubernetes_worker_instances" {
  
  count = var.worker_instance_count

  tags = {
    Name = "worker-${count.index}"
    Project = "kubernetes-the-hard-way"
    InstanceType = "worker"
  }

  ami = "ami-05fb0b8c1424f266b" // Ubuntu Server 20.04
  instance_type = "t2.medium"

  key_name = aws_key_pair.generated_key.key_name
  security_groups = [aws_security_group.vpc_security_group.id]
  subnet_id = aws_subnet.kubernetes.id
  private_ip = "10.240.0.2${count.index}"

  root_block_device {
    volume_size = 20 // In GB
  }

  source_dest_check = false // IP forwarding, 'false' is enabled

  // Role for worker is same as control
  iam_instance_profile = aws_iam_instance_profile.control_plane_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              ${templatefile("../../scripts/pod-cidr.sh.tftpl", { count_index = count.index }) }
              EOF

  }

// EIPs for worker nodes
resource "aws_eip" "worker_eip" {
  count    = var.worker_instance_count
  domain      = "vpc"
  depends_on = [ aws_instance.kubernetes_worker_instances ]
}

// EIP-instance association for worker nodes
resource "aws_eip_association" "worker_eip_assoc" {
  count    = var.worker_instance_count

  instance_id = aws_instance.kubernetes_worker_instances[count.index].id
  allocation_id = aws_eip.worker_eip[count.index].id
}

// ----- Certificates

// Certificate authority and admin-client certificate generation
resource "null_resource" "generate_certs_no_template" {
  triggers = {
    always_run = "${timestamp()}"
  }

  // Doesn't depend on any information generated at apply time
  // ...

  // This doesn't depend on any information created dynamically when we run terraform apply
  provisioner "local-exec" {
    command = "bash ../../scripts/cert-authority.sh; bash ../../scripts/admin-client.sh"
  }

}

// Kubelet client certificate generation
resource "null_resource" "generate_client_cert" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }
  
  // Enforces DAG for cert generation
  depends_on = [ 
      null_resource.generate_certs_no_template,
      aws_eip.control_plane_eip, 
      aws_eip_association.control_plane_eip_assoc,
      aws_eip.worker_eip,
      aws_eip_association.worker_eip_assoc
    ]

  provisioner "local-exec" {

    // TODO: Make this dynamic: on worker names
    command = "bash ../../scripts/client.sh worker ${var.worker_instance_count} \"${join(" ", aws_eip.worker_eip.*.public_ip)}\""

  }

}

// Controller manager client certificate
// TODO: Choose either '-' or '_' between characters, not both
resource "null_resource" "generate_controller_manager_client_cert" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_client_cert
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/controller-manager-client.sh"
  }

}

// Kube proxy client certificate
resource "null_resource" "generate_kube_proxy_client_cert" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_controller_manager_client_cert
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/kube-proxy-client.sh"
  }

}

// Generate kube scheduler certificate
resource "null_resource" "generate_kube_scheduler_cert" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kube_proxy_client_cert
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/kube-scheduler.sh"
  }

}

// Generate API server certificate
resource "null_resource" "generate_kube_api_server_cert" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kube_scheduler_cert
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/api-server.sh ${aws_eip.kubernetes_the_hard_way.public_ip} \"${join(" ", aws_instance.kubernetes_control_plane_instances.*.private_ip)}\""
  }

}

// Worker node private key for SSH
// https://stackoverflow.com/questions/49743220/how-to-create-an-ssh-key-in-terraform
resource "tls_private_key" "worker_ssh_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" { // We are using the same key pair for all instances
  key_name   = "worker-ssh-key-amazon-name"
  public_key = tls_private_key.worker_ssh_private_key.public_key_openssh

  // Output .pem private key file
  provisioner "local-exec" { // Create .pem locally, remove old one if it exists
    command = "rm -f ./${var.private-key-filename}.pem; echo '${tls_private_key.worker_ssh_private_key.private_key_pem}' > ./${var.private-key-filename}.pem; chmod 400 ./${var.private-key-filename}.pem; "
  }

}

// Generate service account key pair
resource "null_resource" "generate_service_account_key_pair" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kube_api_server_cert
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/service-account-key-pair.sh"
  }

}

// Wait for 30s for openssh server to start on instances
resource "time_sleep" "wait_30_seconds" {
    depends_on = [null_resource.generate_service_account_key_pair]
    create_duration = "30s"
}

// Generate kubeconfig for workers
resource "null_resource" "generate_kubeconfig_worker" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    time_sleep.wait_30_seconds
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/kubeconfig-worker.sh \"${join(" ", [for instance in aws_instance.kubernetes_worker_instances : instance.tags["Name"]])}\" ${aws_eip.kubernetes_the_hard_way.public_ip}"
  }

}

// Generate kubeconfig for kubeproxy
resource "null_resource" "generate_kubeconfig_kubeproxy" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kubeconfig_worker
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/kubeconfig-kubeproxy.sh ${aws_eip.kubernetes_the_hard_way.public_ip}"
  }

}

// Generate kubeconfig for kube controller manager
resource "null_resource" "generate_kubeconfig_controllermanager" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kubeconfig_kubeproxy
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/kubeconfig-controller-manager.sh"
  }

}

// Generate kubeconfig for kube scheduler
resource "null_resource" "generate_kubeconfig_kubescheduler" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kubeconfig_controllermanager
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/kubeconfig-kubescheduler.sh"
  }

}

// Generate kubeconfig for admin user
resource "null_resource" "generate_kubeconfig_adminuser" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    null_resource.generate_kubeconfig_kubescheduler
  ]

  provisioner "local-exec" {
    command = "bash ../../scripts/kubeconfig-admin.sh"
  }

}

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
    command = "bash ../../scripts/data-encryption.sh"
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
    inline = [ 
      "${templatefile("../../scripts/bootstrap-controllers.sh.tftpl", { controller_private_ip = "10.240.0.1${count.index}", controller_hostname = "controller-${count.index}", controller_public_address = aws_eip.kubernetes_the_hard_way.public_ip }) }"
     ]
  }
  
}

// Clean up certs & kubeconfig artifacts
resource "null_resource" "clean_up_artifacts" {
  
  // This ensure this re-runs every time we deploy
  triggers = {
    always_run = "${timestamp()}"
  }

  // Enforces the DAG
  depends_on = [
    terraform_data.controller_bootstrap
  ]

  provisioner "local-exec" {
    command = "rm -f *.csr *.pem *.json *.kubeconfig *.yaml"
  }

}

// Resume at 'RBAC for Kubelet Authorization'
