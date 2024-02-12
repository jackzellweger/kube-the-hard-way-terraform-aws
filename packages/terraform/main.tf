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

// Control Plane nodes
resource "aws_instance" "kubernetes_control_plane_instances" {

  for_each = toset([ "1", "2", "3" ])
  
  tags = {
    Name = "controller-${each.value}"
  }

  ami = "ami-05fb0b8c1424f266b" // Ubuntu Server 20.04
  instance_type = "t2.medium"
  security_groups = [aws_security_group.vpc_security_group.id]
  subnet_id = aws_subnet.kubernetes.id
  root_block_device {
    volume_size = 20 // In GB
  }
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

// Policy document we attach to our policy
data "aws_iam_policy_document" "policy-doc-for-control-plane-node" {
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

// Assume Role Policy Document
// Any EC2 can assume this role
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

/*

*/








