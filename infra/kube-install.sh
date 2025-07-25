#!/bin/bash
set -e

WORKER1_IP=$1
WORKER2_IP=$2

echo "[INFO] Installing Kubernetes components..."

# Update system
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

# Fetch stable Kubernetes version safely
K8S_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt || echo "v1.29.0")
if [[ -z "$K8S_VERSION" || "$K8S_VERSION" != v* ]]; then
  echo "[WARN] Failed to fetch stable version, using fallback v1.29.0"
  K8S_VERSION="v1.29.0"
fi
echo "[INFO] Using Kubernetes version: $K8S_VERSION"

# Install kubectl
curl -fsSLo kubectl "https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Install kubeadm, kubelet, kubernetes-cni
sudo apt-get install -y kubeadm kubelet kubernetes-cni

# Initialize master
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl for ubuntu user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Flannel network
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Get join command
JOIN_CMD=$(kubeadm token create --print-join-command)
echo "[INFO] Join command: $JOIN_CMD"

# Copy SSH key and join workers
chmod 600 /home/ubuntu/k8s-key.pem
ssh -o StrictHostKeyChecking=no -i /home/ubuntu/k8s-key.pem ubuntu@$WORKER1_IP "sudo $JOIN_CMD"
ssh -o StrictHostKeyChecking=no -i /home/ubuntu/k8s-key.pem ubuntu@$WORKER2_IP "sudo $JOIN_CMD"
