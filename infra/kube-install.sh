#!/bin/bash
set -e

WORKER1_IP=$1
WORKER2_IP=$2
KEY_FILE="/home/ubuntu/setup/k8s-key.pem"
USER="ubuntu"

echo "[INFO] Installing Kubernetes components on master..."

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Install kubeadm, kubelet, kubectl
sudo apt-get update -y
sudo apt-get install -y apt-transport-https ca-certificates curl

curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Initializing Kubernetes master node..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl for ubuntu user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[INFO] Installing Flannel network plugin..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "[INFO] Generating join command..."
JOIN_CMD=$(kubeadm token create --print-join-command)

# Distribute join command to workers
for ip in $WORKER1_IP $WORKER2_IP; do
  echo "[INFO] Setting up worker at $ip"
  ssh -i $KEY_FILE -o StrictHostKeyChecking=no $USER@$ip "sudo swapoff -a && sudo sed -i '/ swap / s/^/#/' /etc/fstab && sudo apt-get update -y && sudo apt-get install -y apt-transport-https ca-certificates curl && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update -y && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl && sudo $JOIN_CMD"
done

echo "[INFO] Kubernetes cluster setup complete!"
