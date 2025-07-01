# 🚀 Full DevSecOps Microservices Project on Kubernetes with GitLab CI/CD

This repository demonstrates a complete end-to-end DevOps pipeline:

* Infrastructure provisioning
* Kubernetes cluster setup
* Microservices containerization
* GitLab CI/CD automation
* Application deployment into Kubernetes
* Observability and security (later stages)

---

## 📁 Microservices Overview

| Service        | Language | Framework   | Purpose                              |
| -------------- | -------- | ----------- | ------------------------------------ |
| frontend       | Node.js  | Express.js  | User interface & routing gateway     |
| catalogue      | Python   | Flask       | Origami catalogue management         |
| voting         | Java     | Spring Boot | Voting engine for origami            |
| recommendation | Golang   | net/http    | Daily origami recommendation service |

---

## 🧩 Step-by-Step Workflow

### ✅ Step 1: Provision Infrastructure (Terraform)

* Spin up 5 Ubuntu EC2 instances (2 master + 3 worker nodes)
* Use Terraform to auto-provision VPC, subnet, route tables, security groups, and SSH key
* Files:

  * `main.tf`, `network.tf`, `masters.tf`, `workers.tf`, `variables.tf`

### ✅ Step 2: Install Kubernetes

#### Option A: Cloud-init (default)

* Uses `cloud-init/master.yaml` and `cloud-init/worker.yaml`
* Master auto-initializes and applies Flannel
* Workers auto-install kubeadm (join token injected post-init)

#### Option B: Ansible (optional)

* `ansible/install-k8s.yaml`
* Centralized control using SSH and inventory file

### ✅ Step 3: Containerize Microservices

* Each service has its own Dockerfile:

  * `frontend/Dockerfile`
  * `catalogue/Dockerfile`
  * `voting/Dockerfile`
  * `recommendation/Dockerfile`
* Multi-stage builds (optimized for image size)

### ✅ Step 4: Docker Compose for Local Dev

* Use `docker-compose.yaml` to run all services locally for development/testing

### ✅ Step 5: GitLab CI/CD Pipeline

* `.gitlab-ci.yml` defines the pipeline stages:

  * Build Docker images
  * Push to GitLab Container Registry
  * Lint/test scans (Trivy, Snyk)
  * Deploy to Kubernetes using `kubectl`

### ✅ Step 6: Deploy to Kubernetes

* Kubernetes manifests:

  * `deployments/` (yaml files for each service)
  * `services/`, `configmaps/`, `pvc/`
* Auto-applied via CI pipeline

### ✅ Step 7: Helm Packaging (Optional)

* Helm chart for templated deployments (useful for multi-env like dev/stage/prod)

### ✅ Step 8: GitOps & Release Strategy

* Use ArgoCD for GitOps
* Implement Blue/Green and Canary deployments using Argo Rollouts

### ✅ Step 9: Observability (Upcoming)

* Prometheus + Grafana for monitoring
* EFK or Loki for log aggregation

### ✅ Step 10: DevSecOps Pipeline (Upcoming)

* Integrate SAST, DAST, SCA, image scans, and K8s compliance

---

## 🧪 Local Setup Instructions

```bash
# Terraform Infra
cd infra/
terraform init && terraform apply

# (After provisioning)
ssh -i k8s-auto-key.pem ubuntu@<master_ip>

# (Optional) Run Ansible
cd ansible/
ansible-playbook -i inventory.ini install-k8s.yaml
```

---

## 📦 CI/CD Trigger (GitLab)

* Push to main branch triggers CI/CD
* Each microservice folder has its own `.gitlab-ci.yml` logic or combined into root

---

## 🔐 Security Considerations

* Use encrypted GitLab secrets for tokens and credentials
* All SSH keys are auto-generated via Terraform

---

## ✅ Final Notes

* Production-ready structure
* Easily extendable to GCP, Azure, or on-prem
* Helm/Argo makes multi-env deployments simple

---

Maintained by: `Manjunath K`
