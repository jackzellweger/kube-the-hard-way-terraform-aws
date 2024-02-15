base_name=$1 # Base name for workers

num_workers=$2 # Number of workers

# must be run with 'bash' interepreter for this to work
external_ips=($3)

for i in $(seq 0 $((num_workers - 1))); do
    # vars for loop
    instance="${base_name}-${i}"
    external_ip=${external_ips[$i]}

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
                "L": "New York City",
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

    echo LOOP NUMBER ${i}
    echo instance:
    echo ${instance}
    echo external ip:
    echo ${external_ip}
    echo hostnames:
    echo ${instance},${external_ip},10.200.${i}.0/24
    echo

    cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=${instance},${external_ip},10.200.${i}.0/24 \
    -profile=kubernetes \
    ${instance}-csr.json | cfssljson -bare ${instance}
done

echo ${external_ips}