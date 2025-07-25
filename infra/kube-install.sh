#!/bin/bash
set -e

WORKER1=$1
WORKER2=$2

echo "[INFO] Installing Kubernetes components..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Initializing Kubernetes Master..."
sudo kubeadm init --pod-network-cidr=192.168.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[INFO] Installing Calico Network..."
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

JOIN_CMD=$(kubeadm token create --print-join-command)

echo "[INFO] Joining Worker Nodes..."
ssh -o StrictHostKeyChecking=no -i /home/ubuntu/k8s-key.pem ubuntu@$WORKER1 "sudo $JOIN_CMD"
ssh -o StrictHostKeyChecking=no -i /home/ubuntu/k8s-key.pem ubuntu@$WORKER2 "sudo $JOIN_CMD"
