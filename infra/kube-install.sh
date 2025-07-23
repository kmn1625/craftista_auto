#!/bin/bash
set -e

WORKER_NODES="$@"

echo "[INFO] Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "[INFO] Installing dependencies..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

echo "[INFO] Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

echo "[INFO] Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

echo "[INFO] Installing Kubernetes components..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

echo "[INFO] Initializing Kubernetes master node..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

echo "[INFO] Setting up kubeconfig for ubuntu user..."
mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

echo "[INFO] Installing Flannel CNI..."
sudo -u ubuntu kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "[INFO] Generating kubeadm join command..."
JOIN_CMD=$(kubeadm token create --print-join-command)

echo "[INFO] Copying kubeconfig to shared location..."
cp /home/ubuntu/.kube/config /tmp/kubeconfig

echo "[INFO] Joining worker nodes..."
for WORKER in $WORKER_NODES; do
    ssh -o StrictHostKeyChecking=no -i /home/ubuntu/.ssh/id_rsa ubuntu@$WORKER "sudo swapoff -a && sudo $JOIN_CMD"
done

echo "[INFO] Kubernetes cluster setup complete!"
