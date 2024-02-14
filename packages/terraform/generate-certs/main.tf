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