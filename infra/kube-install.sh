#!/bin/bash
set -e

WORKER1_IP=$1
WORKER2_IP=$2

echo "[INFO] Installing Kubernetes on Master..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "[INFO] Initializing Kubernetes cluster..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

JOIN_CMD=$(kubeadm token create --print-join-command)
echo "[INFO] Join Command: $JOIN_CMD"

for WORKER in $WORKER1_IP $WORKER2_IP; do
  ssh -o StrictHostKeyChecking=no -i /home/ubuntu/k8s-key.pem ubuntu@$WORKER "sudo $JOIN_CMD"
done

echo "[INFO] Kubernetes cluster setup completed."
