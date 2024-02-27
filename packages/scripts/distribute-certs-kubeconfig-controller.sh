{   
    # Must be using bash for this to work
    controller_list=($1)

    # Vars
    key_filename=$2
    ec2_user=$3
    ips=($4)

    # Echo vars
    echo

    echo Controller List:
    for worker in "${controller_list[@]}"; do
        echo $worker
    done
    echo

    
    echo Key filename:
    echo $key_filename
    echo

    echo Certificate name:
    echo $cert_name
    echo

    echo EC2 User:
    echo $ec2_user
    echo

    echo IPs:
    for ip in $ips; do
        echo $ip
    done
    echo

    # See command
    echo Running command...
    echo "scp -i ${key_filename}.pem ${cert_name}.txt ${ec2_user}@${ips[i]}:~/."
    echo

    echo

    # Proper permissions on key for file transfer
    chmod 400 ${key_filename}.pem

    # DNS name looks like: 'mec2-50-17-16-67.compute-1.amazonaws.com'
    # TODO: Replace .txt with .pem or whatever
    for ((i=0; i<${#controller_list[@]}; i++)); do
        # This is what it's supposed to look like when interpolated:
        # scp -o StrictHostKeyChecking=no -i worker-ssh-private-key.pem test.txt ubuntu@3.130.100.52:~/.
        scp -o StrictHostKeyChecking=no -i ${key_filename}.pem ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem service-account-key.pem service-account.pem ${ec2_user}@${ips[i]}:~/.
        scp -o StrictHostKeyChecking=no -i ${key_filename}.pem admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig ${ec2_user}@${ips[i]}:~/.
        scp -o StrictHostKeyChecking=no -i ${key_filename}.pem encryption-config.yaml ${ec2_user}@${ips[i]}:~/.
    done

}