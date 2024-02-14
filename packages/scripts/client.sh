base_name=$1 # Base name for workers

num_workers=$2 # Number of workers

external_ips=($3)

internal_ips=($4)

for i in $(seq 0 $((num_workers - 1))); do
    # vars for loop
    instance="${base_name}-${i}"
    external_ip=${external_ips[$i]}
    internal_ip=${internal_ips[$i]}

    # work
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
                "L": "New York",
                "O": "system:nodes",
                "OU": "Kubernetes The Hard Way",
                "ST": "New York"
            }
        ]
    }
EOF

    # Assuming EXTERNAL_IP should be set here, the script as provided does not include a method to set it
    #EXTERNAL_IP=$(# Command to get external IP, placeholder)

    #INTERNAL_IP=$(gcloud compute instances describe ${instance} \
    #--format 'value(networkInterfaces[0].networkIP)')

    cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${instance},${external_ip},${external_ip} \
    -profile=kubernetes \
    ${instance}-csr.json | cfssljson -bare ${instance}
done