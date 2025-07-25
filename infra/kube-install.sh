#!/bin/bash
set -e

WORKER1=$1
WORKER2=$2
SSH_KEY="/home/ubuntu/k8s-key.pem"

echo "[INFO] Installing Kubernetes components..."
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Initializing Kubernetes Master..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[INFO] Installing Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

JOIN_CMD=$(kubeadm token create --print-join-command)
echo "[INFO] Join command: $JOIN_CMD"

echo "[INFO] Copying SSH key and joining workers..."
chmod 600 $SSH_KEY
for NODE in $WORKER1 $WORKER2; do
  ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$NODE "sudo apt-get update && sudo apt-get install -y apt-transport-https curl"
  ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$NODE "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -"
  ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$NODE "echo 'deb https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list"
  ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$NODE "sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl && sudo apt-mark hold kubelet kubeadm kubectl"
  ssh -i $SSH_KEY -o StrictHostKeyChecking=no ubuntu@$NODE "sudo $JOIN_CMD"
done

echo "[INFO] Kubernetes cluster setup completed successfully."
