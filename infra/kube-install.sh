#!/bin/bash
WORKER1_IP=$1
WORKER2_IP=$2

echo "[INFO] Updating system and installing Kubernetes..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Initializing Kubernetes Master..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

echo "[INFO] Configuring kubeconfig..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

echo "[INFO] Installing Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

JOIN_CMD=$(kubeadm token create --print-join-command)

echo "[INFO] Joining workers..."
for WORKER in $WORKER1_IP $WORKER2_IP; do
    ssh -i /home/ubuntu/k8s-key.pem -o StrictHostKeyChecking=no ubuntu@$WORKER "sudo $JOIN_CMD"
done

echo "[INFO] Cluster setup complete."
