#!/bin/bash
ROLE=$1
MASTER_IP=$2
WORKER1_IP=$3
WORKER2_IP=$4

install_k8s() {
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https curl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
    echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt-get update -y
    sudo apt-get install -y docker.io kubelet kubeadm kubectl
    sudo systemctl enable docker && sudo systemctl start docker
}

if [ "$ROLE" == "master" ]; then
    install_k8s
    sudo kubeadm init --apiserver-advertise-address=$MASTER_IP --pod-network-cidr=192.168.0.0/16
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    TOKEN=$(kubeadm token create --print-join-command)
    ssh -o StrictHostKeyChecking=no ubuntu@$WORKER1_IP "$TOKEN"
    ssh -o StrictHostKeyChecking=no ubuntu@$WORKER2_IP "$TOKEN"
else
    install_k8s
fi
