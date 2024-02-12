// ----- Providers

provider "aws" {
  region = "us-east-2"
}

// ----- Variables



// ----- Resources

// Our VPC
resource "aws_vpc" "kubernetes-the-hard-way" {
  cidr_block = "10.240.0.0/24"
}

// Our subnet attached to our VPC
resource "aws_subnet" "kubernetes" {
  vpc_id = aws_vpc.kubernetes-the-hard-way.id
  cidr_block = "10.240.0.0/24"
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

}

// Static IP for our load balancer
resource "aws_eip" "lb_ip" {
  // GCloud Command:
  // gcloud compute addresses create kubernetes-the-hard-way \
  // --region $(gcloud config get-value compute/region)
  
  domain = "vpc"
  // Do we need a region?
}


// Instances
// Ubuntu Server 20.04
resource "aws_instance" "kubernetes_control_plane_instances" {
  // GCloud Command:
  # for i in 0 1 2; do
  # gcloud compute instances create controller-${i} \
  #   --async \
  #   --boot-disk-size 200GB \
  #   --can-ip-forward \
  #   --image-family ubuntu-2004-lts \
  #   --image-project ubuntu-os-cloud \
  #   --machine-type e2-standard-2 \
  #   --private-network-ip 10.240.0.1${i} \
  #   --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
  #   --subnet kubernetes \
  #   --tags kubernetes-the-hard-way,controller
  # done

  // -----

  for_each = toset([ "1", "2", "3" ])

  tags = {
    Name = "controller-${each.value}"
  }

  ami = "ami-05fb0b8c1424f266b"
  instance_type = "t2.medium"
  security_groups = [aws_security_group.vpc_security_group]
  subnet_id = aws_subnet.kubernetes

  root_block_device {
    volume_size = 200 // In GB
  }
}

resource "aws_iam_role" "control-plane-node-iam-role" {
  name = "control-plane-node-iam-role"


}

resource "aws_iam_policy_attachment" "control-plane-node-iam-role-policy-attachment" {
  // --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring
}









