# CloudOps Platform ☁️

> A production-style cloud-native DevOps platform built with AWS, Terraform, Kubernetes, Jenkins, Docker, Helm, HashiCorp Vault, Prometheus, and Grafana.

---

## 🚀 Overview

**CloudOps Platform** is an end-to-end cloud and DevOps project designed to demonstrate how a containerized MERN application can be built, tested, secured, deployed, and monitored on AWS.

The project combines infrastructure automation, Kubernetes orchestration, CI/CD, secret management, cloud load balancing, persistent storage, and observability into a single platform.

### Core workflow

```text
Developer
    ↓
GitHub
    ↓
Jenkins CI/CD
    ↓
Automated Tests
    ↓
Docker Build
    ↓
Docker Hub
    ↓
Amazon EKS
    ↓
Helm Deployment
    ↓
AWS Application Load Balancer
    ↓
MERN Application

HashiCorp Vault
    ↓
Application Secrets

Prometheus
    ↓
Grafana
    ↓
Monitoring & Observability
```

---

## 🏗️ Architecture

```text
                              GitHub
                                 |
                                 v
                          Jenkins CI/CD
                                 |
                  +--------------+--------------+
                  |                             |
                  v                             v
           Backend Tests                Frontend Build
                  |                             |
                  +--------------+--------------+
                                 |
                                 v
                            Docker Build
                                 |
                                 v
                            Docker Hub
                           /           \
                          v             v
                    Backend Image   Frontend Image
                          \             /
                           \           /
                            +----+----+
                                 |
                                 v
                         Amazon EKS Cluster
                                 |
                                 v
                      Kubernetes Ingress
                                 |
                                 v
                   AWS Application Load Balancer
                                 |
                    +------------+------------+
                    |                         |
                    v                         v
             Frontend Service          Backend Service
                    |                         |
                    v                         v
             Frontend Pods              Backend Pods
                                              |
                           +------------------+------------------+
                           |                                     |
                           v                                     v
                     HashiCorp Vault                         MongoDB
                           |                                     |
                           v                                     v
                    Vault Agent Sidecar                     EBS gp3
                           |
                           v
                    Injected Secrets


                         Monitoring
                              |
                     +--------+--------+
                     |                 |
                     v                 v
                Prometheus          Grafana
                     |
                     v
             Kubernetes Metrics
```

For the detailed architecture, see:

**[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)**

---

## 🛠️ Technology Stack

| Category               | Technology                    |
| ---------------------- | ----------------------------- |
| Cloud                  | AWS                           |
| Infrastructure as Code | Terraform                     |
| Containerization       | Docker                        |
| Container Registry     | Docker Hub                    |
| Orchestration          | Kubernetes                    |
| Managed Kubernetes     | Amazon EKS                    |
| Package Management     | Helm                          |
| CI/CD                  | Jenkins                       |
| Load Balancer          | AWS Application Load Balancer |
| Ingress                | AWS Load Balancer Controller  |
| Secrets                | HashiCorp Vault               |
| Monitoring             | Prometheus                    |
| Visualization          | Grafana                       |
| Backend                | Node.js / Express             |
| Frontend               | React                         |
| Database               | MongoDB                       |
| Persistent Storage     | Amazon EBS gp3                |
| Version Control        | Git / GitHub                  |

---

# ☁️ AWS Infrastructure

## VPC

The platform uses a custom AWS VPC:

```text
CIDR: 10.0.0.0/16
Region: ap-southeast-2
```

### Public Subnets

| Subnet   | CIDR          | AZ                |
| -------- | ------------- | ----------------- |
| Public A | `10.0.1.0/24` | `ap-southeast-2a` |
| Public B | `10.0.2.0/24` | `ap-southeast-2b` |

### Private Subnets

| Subnet    | CIDR           | AZ                |
| --------- | -------------- | ----------------- |
| Private A | `10.0.11.0/24` | `ap-southeast-2a` |
| Private B | `10.0.12.0/24` | `ap-southeast-2b` |

### Network Components

* VPC
* Internet Gateway
* NAT Gateway
* Elastic IP
* Public route table
* Private route table
* Security groups
* Private EKS workloads

---

# ☸️ Amazon EKS

The application runs on **Amazon Elastic Kubernetes Service (EKS)**.

### Cluster

```text
Cluster: cloudops-platform-dev-eks
Kubernetes: 1.33
Region: ap-southeast-2
```

### Managed Node Group

```text
Instance Type: t3.small
Nodes: 3
Minimum: 1
Maximum: 3
```

Worker nodes run inside the private subnets.

---

## Kubernetes Workloads

The application runs inside the:

```text
cloudops
```

namespace.

### Frontend

```text
Replicas: 2
Service: ClusterIP
```

### Backend

```text
Replicas: 2
Service: ClusterIP
```

### MongoDB

```text
Replicas: 1
StatefulSet
PersistentVolumeClaim
EBS gp3
```

---

# 🐳 Docker

The application is containerized into separate frontend and backend images.

### Backend

```text
jeevanjacob11/cloudops-backend
```

### Frontend

```text
jeevanjacob11/cloudops-frontend
```

Images are published using:

```text
1.0.<BUILD_NUMBER>
latest
```

Versioned tags make deployments traceable to specific Jenkins builds.

---

# 🔄 CI/CD with Jenkins

Jenkins automates the complete application delivery process.

## Pipeline

```text
GitHub
   ↓
Checkout
   ↓
Backend Tests
   ↓
Frontend Build
   ↓
Docker Build
   ↓
Docker Hub Push
   ↓
Update EKS kubeconfig
   ↓
Helm Upgrade
   ↓
Kubernetes Rollout
   ↓
Deployment Verification
```

### Pipeline Stages

1. Checkout
2. Test Backend
3. Build Frontend
4. Build Docker Images
5. Push Docker Images
6. Deploy to EKS
7. Verify Deployment

The backend API includes automated tests using **Jest and Supertest**.

---

# ⎈ Helm

The application is packaged and deployed using Helm.

Chart:

```text
helm/cloudops-app
```

Release:

```text
cloudops-app
```

Namespace:

```text
cloudops
```

Helm manages:

* Frontend deployment
* Backend deployment
* MongoDB StatefulSet
* Services
* Ingress
* Service accounts
* Application configuration

### Current Verified Release

```text
Status: deployed
Revision: 7
```

---

# 🔐 HashiCorp Vault

HashiCorp Vault manages application secrets.

The backend uses Kubernetes authentication with Vault.

## Secret Flow

```text
Kubernetes Service Account
          ↓
Vault Kubernetes Auth
          ↓
Vault Role
          ↓
Vault Policy
          ↓
KV Secret
          ↓
Vault Agent Sidecar
          ↓
/vault/secrets/config
          ↓
Backend Application
```

The MongoDB connection configuration is stored in Vault instead of directly inside the application deployment configuration.

### Backend Pod

Each backend pod contains:

```text
backend
vault-agent
```

Both containers were verified as running and ready.

---

# ⚖️ AWS Application Load Balancer

The AWS Load Balancer Controller manages the Kubernetes Ingress.

Traffic flow:

```text
Internet
   ↓
AWS Application Load Balancer
   ↓
Kubernetes Ingress
   ↓
Frontend / Backend Services
   ↓
Application Pods
```

The external backend health endpoint was successfully verified:

```text
/api/health
```

Response:

```json
{
  "status": "healthy",
  "service": "cloudops-backend"
}
```

---

# 💾 Persistent Storage

MongoDB uses persistent storage through the AWS EBS CSI driver.

### StorageClass

```text
gp3
```

Configuration includes:

* Amazon EBS CSI
* gp3 storage
* 10 GiB MongoDB PVC
* `WaitForFirstConsumer`
* `allowVolumeExpansion`

This allows MongoDB data to survive MongoDB pod recreation.

---

# 📊 Monitoring & Observability

The monitoring stack uses:

* Prometheus
* Grafana
* kube-state-metrics
* Node Exporter
* Kubelet metrics
* cAdvisor
* Prometheus Operator

## Monitoring Flow

```text
Kubernetes
    ↓
Metrics
    ↓
Prometheus
    ↓
Grafana
    ↓
Dashboards
```

### Verified Prometheus Targets

* Kubernetes API Server
* CoreDNS
* Grafana
* kube-proxy
* kube-state-metrics
* Kubelet
* Kubelet cAdvisor
* Prometheus Operator
* Node Exporter
* Prometheus

### Grafana Dashboards

The environment includes dashboards for:

* Kubernetes / Kubelet
* Kubernetes / Networking
* Kubernetes / Pods
* Kubernetes / Workloads
* Kubernetes / Persistent Volumes
* Node Exporter
* Prometheus
* Kubernetes infrastructure

The Grafana Prometheus datasource was successfully tested.

---

# 🧪 Verification

The platform was tested end-to-end after deployment.

### Application Pods

```text
Backend:
2/2 Running

Frontend:
2/2 Running

MongoDB:
1/1 Running
```

### Application Health

```json
{
  "status": "healthy",
  "service": "cloudops-backend"
}
```

### Backend Logs

```text
MongoDB connected
```

### Backend Containers

```text
backend
vault-agent
```

Both containers were verified as ready.

### Helm

```text
Release: cloudops-app
Status: deployed
Revision: 7
```

### Pod Restarts

Application pods were verified with:

```text
0 restarts
```

### CI/CD

The Jenkins pipeline completed successfully after automated backend testing was added.

---

# 📁 Project Structure

```text
CloudOps-Platform/
│
├── app/
│   ├── backend/
│   │   ├── server.js
│   │   ├── server.test.js
│   │   ├── package.json
│   │   └── Dockerfile
│   │
│   └── frontend/
│       ├── src/
│       ├── package.json
│       └── Dockerfile
│
├── docs/
│   └── ARCHITECTURE.md
│
├── helm/
│   └── cloudops-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── kubernetes/
│
├── monitoring/
│   └── kube-prometheus-values.yaml
│
├── terraform/
│   ├── modules/
│   │   ├── vpc/
│   │   ├── iam/
│   │   ├── eks/
│   │   └── jenkins/
│   │
│   └── environments/
│       └── dev/
│
├── vault/
│
├── Jenkinsfile
├── README.md
└── .gitignore
```

---

# 🧱 Terraform Architecture

Terraform is organized using reusable modules.

```text
terraform/
│
├── modules/
│   ├── vpc/
│   ├── iam/
│   ├── eks/
│   └── jenkins/
│
└── environments/
    └── dev/
```

Terraform provisions:

* VPC
* Subnets
* Internet Gateway
* NAT Gateway
* Route tables
* IAM roles
* EKS cluster
* EKS node group
* Jenkins EC2
* Security groups
* EKS access configuration

Terraform state is stored remotely in an encrypted Amazon S3 backend.

---

# 🔒 Security Practices

The project implements several cloud security practices.

### Network

* EKS worker nodes run in private subnets.
* Application services use ClusterIP.
* Public traffic enters through the ALB.
* Worker nodes are not directly exposed to the internet.

### IAM

* AWS IAM roles are used for AWS access.
* Jenkins uses an IAM role.
* Static AWS credentials are not embedded in the application.

### Kubernetes

* EKS access entries control cluster access.
* Jenkins has scoped deployment permissions.
* Application workloads use Kubernetes ServiceAccounts.

### Secrets

* Application secrets are stored in Vault.
* Docker Hub credentials are stored in Jenkins credentials.
* Secrets are not committed to Git.

### Terraform

* Remote state is stored in S3.
* State is encrypted.
* State locking is enabled.

---

# 📚 Key DevOps Concepts Demonstrated

This project demonstrates practical experience with:

* AWS VPC design
* Public/private subnet architecture
* NAT Gateway
* IAM
* Terraform modules
* Terraform remote state
* Amazon EKS
* Kubernetes deployments
* Kubernetes services
* StatefulSets
* Persistent volumes
* EBS CSI
* Docker
* Docker Hub
* Jenkins pipelines
* CI/CD
* Helm
* AWS Load Balancer Controller
* Application Load Balancer
* HashiCorp Vault
* Kubernetes authentication
* Prometheus
* Grafana
* Kubernetes monitoring
* Linux
* Git/GitHub
* Automated testing

---

# 🎯 What This Project Demonstrates

CloudOps Platform demonstrates the complete DevOps lifecycle:

```text
                PLAN
                 ↓
             Terraform
                 ↓
               BUILD
                 ↓
          Docker + Jenkins
                 ↓
               TEST
                 ↓
        Jest + Supertest
                 ↓
              PACKAGE
                 ↓
                Helm
                 ↓
              DEPLOY
                 ↓
              Amazon EKS
                 ↓
              SECURE
                 ↓
         HashiCorp Vault
                 ↓
             MONITOR
                 ↓
       Prometheus + Grafana
```

---

# ⚠️ Production Considerations

This project is designed as a cloud and DevOps portfolio platform.

Some components are intentionally simplified for learning and cost control.

### Vault

The current Vault deployment uses development-oriented storage.

A production environment should use:

* Persistent storage
* High availability
* TLS
* Backup and recovery
* Production authentication
* Proper unsealing strategy

### Grafana

Grafana persistence is disabled in the current environment.

A production deployment should use persistent storage for dashboards and configuration.

### EKS

The current node group uses three `t3.small` nodes.

Production sizing should consider:

* CPU requirements
* Memory requirements
* Pod density
* Autoscaling
* Availability
* Workload growth
* Cost optimization

---

# 💰 Cost Awareness

The platform was designed with cloud cost awareness in mind.

Resources that can be stopped or destroyed when the project is not being demonstrated include:

* Jenkins EC2
* EKS node group
* EKS cluster
* NAT Gateway
* Other temporary EC2 resources

The Jenkins EC2 instance is intentionally stopped when not required.

Before deleting production-like resources, Terraform state and the AWS environment should be reviewed carefully.

---

# 🧹 Cleanup

To remove Terraform-managed infrastructure:

```bash
terraform destroy
```

Run this only from the appropriate Terraform environment and after verifying what Terraform plans to remove.

For portfolio demonstrations, the environment can be recreated using Terraform rather than keeping all AWS resources running continuously.

---

# 🏆 Project Summary

**CloudOps Platform** is a complete cloud-native DevOps project that demonstrates how modern infrastructure and application delivery can be automated using AWS, Terraform, Docker, Kubernetes, Jenkins, Helm, Vault, Prometheus, and Grafana.

The project focuses on practical implementation rather than isolated tutorials, bringing infrastructure, deployment, security, and monitoring together into one platform.

---

## 👨‍💻 Author

**Jeevan Jacob**

B.Tech — Artificial Intelligence & Data Science

Cloud & DevOps Engineer

GitHub: `jeevan11jacob-svg`

LinkedIn: `jeevan-jacob1`
