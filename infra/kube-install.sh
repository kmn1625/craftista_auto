#!/bin/bash
WORKER1_IP=$1
WORKER2_IP=$2

echo "[INFO] Installing Kubernetes components on Master..."
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Initializing Master node..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[INFO] Installing Flannel network..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo "[INFO] Generating join command..."
JOIN_CMD=$(kubeadm token create --print-join-command)

echo "[INFO] Copying join command to workers..."
ssh -i k8s-key.pem -o StrictHostKeyChecking=no ubuntu@$WORKER1_IP "sudo $JOIN_CMD"
ssh -i k8s-key.pem -o StrictHostKeyChecking=no ubuntu@$WORKER2_IP "sudo $JOIN_CMD"
