#!/bin/bash

WORKER1=$1
WORKER2=$2
KEY="/home/ubuntu/k8s-key.pem"
USER="ubuntu"

echo "[INFO] Installing Kubernetes on Master Node..."
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Initializing Kubernetes Cluster..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[INFO] Installing Flannel Network..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

JOIN_CMD=$(kubeadm token create --print-join-command)
echo "[INFO] Join command: $JOIN_CMD"

for WORKER in $WORKER1 $WORKER2; do
  echo "[INFO] Joining worker: $WORKER"
  for i in {1..10}; do
    if ssh -o StrictHostKeyChecking=no -i $KEY $USER@$WORKER "echo 'SSH OK'" 2>/dev/null; then
      ssh -o StrictHostKeyChecking=no -i $KEY $USER@$WORKER "sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add - && echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update && sudo apt-get install -y kubelet kubeadm && sudo $JOIN_CMD"
      break
    fi
    echo "[WARN] Retry SSH for $WORKER in 10s..."
    sleep 10
  done
done
