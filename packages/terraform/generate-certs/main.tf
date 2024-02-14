// ----- Providers

provider "aws" {
  region = "us-east-2"
}

// ----- Variables

variable "control_plane_instances" {
  type = map(string)
  default = {
    "control-1" = "0",
    "control-2" = "1"
  }
}

variable "worker_instances" {
  type = number
  default = 2
}

// ----- Resources
/*
resource "null_resource" "test_null_resource" {

    for_each = tomap(var.worker_instances)
    
    triggers = {
        always_run = "${timestamp()}"
    }

    provisioner "local-exec" {
        command = "echo ${each.key} ${each.value}"
    }

}
*/

/*
resource "aws_instance" "kubernetes_control_plane_instances" {

  for_each = tomap(var.control_plane_instances)
  
  tags = {
    Name = "controller-${each.value}"
    Project = "kubernetes-the-hard-way"
    InstanceType = "controller"
  }

  ami = "ami-05fb0b8c1424f266b" // Ubuntu Server 20.04
  instance_type = "t2.medium"
  security_groups = [aws_security_group.vpc_security_group.id]
  subnet_id = aws_subnet.kubernetes.id
  private_ip = "10.240.0.1${each.value}"
  
  root_block_device {
    volume_size = 20 // In GB
  }

  source_dest_check = false // IP forwarding, 'false' is enabled

  iam_instance_profile = aws_iam_instance_profile.control_plane_instance_profile.name

}
*/


/*
// Certificates
resource "null_resource" "generate_certs_no_template" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "zsh ../../pki/cert-authority.sh && zsh ../../pki/admin-client.sh && zsh"
  }

}
*/

/*
resource "null_resource" "generate_certs_template" {
  
  triggers = {
    always_run = "${timestamp()}"
  }
  
  depends_on = [ null_resource.generate_certs_no_template ]

  provisioner "local-exec" {
    command = <<-EOT
                for instance in worker-0 worker-1 worker-2; do
                cat > ${instance}-csr.json <<EOF
                {
                "CN": "system:node:${instance}",
                "key": {
                    "algo": "rsa",
                    "size": 2048
                },
                "names": [
                    {
                    "C": "US",
                    "L": "Portland",
                    "O": "system:nodes",
                    "OU": "Kubernetes The Hard Way",
                    "ST": "Oregon"
                    }
                ]
                }
                EOF

                EXTERNAL_IP=$

                INTERNAL_IP=$(gcloud compute instances describe ${instance} \
                --format 'value(networkInterfaces[0].networkIP)')

                cfssl gencert \
                -ca=ca.pem \
                -ca-key=ca-key.pem \
                -config=ca-config.json \
                -hostname=${instance},${EXTERNAL_IP},${INTERNAL_IP} \
                -profile=kubernetes \
                ${instance}-csr.json | cfssljson -bare ${instance}
                done
            EOT
  }

}

*/