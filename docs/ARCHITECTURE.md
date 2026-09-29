# CloudOps Platform — Architecture

## Overview

CloudOps Platform is a production-style DevOps and cloud infrastructure project built around a containerized MERN task-management application.

The platform demonstrates:

* Infrastructure as Code with Terraform
* Containerization with Docker
* Kubernetes orchestration with Amazon EKS
* CI/CD with Jenkins
* Application deployment with Helm
* Secret management with HashiCorp Vault
* AWS Application Load Balancer
* Monitoring with Prometheus and Grafana
* Persistent storage with Amazon EBS

---

## High-Level Architecture

```text
                         GitHub
                            |
                            v
                     Jenkins CI/CD
                            |
              +-------------+-------------+
              |                           |
              v                           v
       Backend Tests              Frontend Build
              |                           |
              +-------------+-------------+
                            |
                            v
                       Docker Build
                            |
                            v
                       Docker Hub
                     /             \
                    v               v
          Backend Image       Frontend Image
                    \               /
                     \             /
                      +-----+-----+
                            |
                            v
                    Amazon EKS Cluster
                            |
                            v
                 Kubernetes Ingress
                            |
                            v
                AWS Application Load
                     Balancer
                            |
              +-------------+-------------+
              |                           |
              v                           v
       Frontend Service            Backend Service
              |                           |
              v                           v
       Frontend Pods               Backend Pods
                                          |
                            +-------------+-------------+
                            |                           |
                            v                           v
                       HashiCorp Vault             MongoDB
                            |                           |
                            v                           v
                     Vault Agent Sidecar          EBS gp3 PVC
                            |
                            v
                     Injected Secrets


                    Monitoring Layer
                            |
                +-----------+-----------+
                |                       |
                v                       v
           Prometheus                Grafana
                |                       |
                +-----------+-----------+
                            |
                            v
                    Kubernetes Metrics


                    Infrastructure Layer
                            |
                            v
                        Terraform
                            |
                            v
                    AWS Infrastructure
```

---

## AWS Architecture

The infrastructure is deployed in the AWS `ap-southeast-2` region.

### VPC

The platform uses a custom VPC:

```text
VPC CIDR: 10.0.0.0/16
```

The VPC is divided into public and private subnets across two Availability Zones.

### Network Layout

```text
                    AWS VPC
                10.0.0.0/16
                      |
        +-------------+-------------+
        |                           |
        v                           v
   Public Subnets             Private Subnets
        |                           |
        |                           |
   Internet Gateway            NAT Gateway
        |                           |
        |                           |
        v                           v
   Internet Access           Outbound Access
```

### Public Subnets

| Subnet   | CIDR          | Availability Zone |
| -------- | ------------- | ----------------- |
| Public A | `10.0.1.0/24` | `ap-southeast-2a` |
| Public B | `10.0.2.0/24` | `ap-southeast-2b` |

### Private Subnets

| Subnet    | CIDR           | Availability Zone |
| --------- | -------------- | ----------------- |
| Private A | `10.0.11.0/24` | `ap-southeast-2a` |
| Private B | `10.0.12.0/24` | `ap-southeast-2b` |

The EKS worker nodes and application workloads run in the private subnets.

---

## Amazon EKS

Amazon EKS provides the Kubernetes control plane for the platform.

### EKS Configuration

* Cluster: `cloudops-platform-dev-eks`
* Kubernetes version: `1.33`
* Region: `ap-southeast-2`
* Managed node group
* Instance type: `t3.small`
* Node count: 3
* Worker nodes deployed in private subnets

The three-node configuration provides sufficient pod capacity for the application and monitoring workloads.

---

## Kubernetes Architecture

The application runs inside the `cloudops` namespace.

### Application Components

```text
cloudops namespace
│
├── Frontend
│   ├── Replica 1
│   └── Replica 2
│
├── Backend
│   ├── Replica 1
│   └── Replica 2
│
└── MongoDB
    └── StatefulSet
```

### Frontend

The frontend is a React application.

Configuration:

* 2 replicas
* ClusterIP service
* Containerized using Docker
* Served through the AWS Application Load Balancer

### Backend

The backend is a Node.js / Express API.

Configuration:

* 2 replicas
* ClusterIP service
* Vault Agent sidecar
* MongoDB integration
* Kubernetes health verification

Each backend pod contains:

```text
backend
vault-agent
```

Both containers were verified as ready.

### MongoDB

MongoDB is deployed as a Kubernetes StatefulSet.

Configuration:

* MongoDB 7
* 1 replica
* ClusterIP service
* PersistentVolumeClaim
* AWS EBS gp3 storage

---

## Application Traffic Flow

External application traffic follows this path:

```text
Internet
   |
   v
AWS Application Load Balancer
   |
   v
Kubernetes Ingress
   |
   +----------------------+
   |                      |
   v                      v
Frontend Service      Backend Service
   |                      |
   v                      v
Frontend Pods         Backend Pods
                            |
                            v
                         MongoDB
```

The application is exposed through the AWS Application Load Balancer created by the AWS Load Balancer Controller.

The backend health endpoint was externally verified through the ALB:

```text
/api/health
```

Expected response:

```json
{
  "status": "healthy",
  "service": "cloudops-backend"
}
```

---

## Infrastructure as Code

Terraform manages the AWS infrastructure.

Project structure:

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

### Terraform Modules

#### VPC Module

Manages:

* VPC
* Public subnets
* Private subnets
* Internet Gateway
* NAT Gateway
* Route tables
* Route associations
* Elastic IP

#### IAM Module

Manages IAM roles and policies required for:

* EKS control plane
* EKS worker nodes
* Jenkins
* AWS services

#### EKS Module

Manages:

* EKS cluster
* EKS access configuration
* Node group
* Kubernetes API access
* Jenkins EKS permissions

#### Jenkins Module

Manages:

* Jenkins EC2 instance
* Security group
* IAM instance profile
* Jenkins bootstrap configuration

---

## Terraform State

Terraform state is stored remotely in Amazon S3.

Configuration:

```text
Bucket:
jeevan-cloudops-terraform-state

Region:
ap-southeast-2

State Key:
cloudops/dev/terraform.tfstate
```

The S3 backend uses encryption and Terraform state locking.

This prevents the infrastructure state from being tied to a single local machine.

---

## CI/CD Architecture

Jenkins provides the CI/CD pipeline.

### Pipeline Flow

```text
Developer
    |
    v
GitHub
    |
    v
Jenkins
    |
    +--> Checkout
    |
    +--> Backend Tests
    |
    +--> Frontend Build
    |
    +--> Docker Build
    |
    +--> Docker Hub Push
    |
    +--> Helm Deployment
    |
    +--> Kubernetes Rollout
    |
    +--> Deployment Verification
```

### Jenkins Pipeline Stages

1. Checkout source code
2. Install backend dependencies
3. Run backend tests
4. Build frontend
5. Build Docker images
6. Login to Docker Hub
7. Push versioned Docker images
8. Push latest Docker images
9. Update EKS kubeconfig
10. Deploy application using Helm
11. Wait for Kubernetes rollouts
12. Verify pods and Helm release

---

## Docker Images

The application uses two Docker images.

### Backend

```text
jeevanjacob11/cloudops-backend
```

### Frontend

```text
jeevanjacob11/cloudops-frontend
```

Images are tagged with both:

```text
1.0.<BUILD_NUMBER>
latest
```

This allows Jenkins to create traceable application versions while maintaining a latest tag.

---

## Helm Deployment

The Kubernetes application is packaged using Helm.

Chart location:

```text
helm/cloudops-app
```

Chart structure:

```text
cloudops-app/
│
├── Chart.yaml
├── values.yaml
└── templates/
    ├── backend
    ├── frontend
    ├── mongodb
    ├── services
    ├── ingress
    └── service accounts
```

The Helm release is:

```text
cloudops-app
```

Namespace:

```text
cloudops
```

The application was successfully deployed using Helm and reached:

```text
STATUS: deployed
REVISION: 7
```

---

## Secret Management with HashiCorp Vault

HashiCorp Vault is integrated with Kubernetes to manage application secrets.

The backend does not directly store the MongoDB connection string inside the Deployment configuration.

### Vault Flow

```text
Kubernetes Service Account
          |
          v
    Vault Kubernetes Auth
          |
          v
       Vault Role
          |
          v
      Vault Policy
          |
          v
      KV Secret
          |
          v
   Vault Agent Sidecar
          |
          v
 /vault/secrets/config
          |
          v
      Backend
```

The backend uses the Vault Agent sidecar to retrieve the MongoDB configuration.

The secret is stored in Vault under:

```text
secret/cloudops/backend
```

The policy grants the backend read access to the required secret.

---

## Vault Authentication

The backend Kubernetes ServiceAccount is bound to the Vault role:

```text
cloudops-backend
```

Vault authenticates the Kubernetes workload using Kubernetes authentication.

This avoids placing static secrets directly into the application repository or Kubernetes manifest.

The backend pods were verified with both:

```text
backend
vault-agent
```

containers running and ready.

Backend logs also confirmed:

```text
MongoDB connected
```

---

## Persistent Storage

MongoDB uses Kubernetes persistent storage backed by Amazon EBS.

Storage class:

```text
gp3
```

Configuration includes:

* EBS CSI driver
* gp3 volumes
* 10 GiB MongoDB PVC
* WaitForFirstConsumer volume binding
* Filesystem: ext4

This allows MongoDB data to be stored independently of the MongoDB container lifecycle.

---

## Monitoring Architecture

The platform uses Prometheus and Grafana for observability.

```text
Kubernetes Cluster
        |
        +--------------------+
        |                    |
        v                    v
   kube-state-metrics   Node Exporter
        |                    |
        +---------+----------+
                  |
                  v
             Prometheus
                  |
                  v
              Grafana
                  |
                  v
           Dashboards
```

### Prometheus

Prometheus collects Kubernetes and node metrics.

Verified targets include:

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

### Grafana

Grafana provides dashboards for:

* Kubernetes nodes
* Kubelets
* Pods
* Workloads
* Networking
* Persistent volumes
* Node metrics
* Prometheus
* Kubernetes resources

The Prometheus datasource was successfully tested through Grafana.

---

## Monitoring Namespace

Monitoring components run in:

```text
monitoring
```

The monitoring stack is installed using:

```text
kube-prometheus-stack
```

The stack includes:

* Prometheus
* Grafana
* Prometheus Operator
* kube-state-metrics
* Node Exporter
* Kubelet metrics
* cAdvisor metrics

---

## Security Design

The platform implements several security practices.

### Network Security

* Application workloads run in private EKS subnets.
* Frontend and backend Kubernetes services use ClusterIP.
* Public traffic enters through the AWS Application Load Balancer.
* Worker nodes are not directly exposed to the internet.

### IAM

AWS IAM roles are used for AWS service access.

Static AWS credentials are not embedded into the application.

### Kubernetes Access

EKS access entries and access policies are used to control Jenkins access to the cluster.

Jenkins is granted the required namespace-level permissions for deployment.

### Secrets

Application secrets are stored in HashiCorp Vault.

Docker Hub credentials are stored in Jenkins credentials rather than directly inside the Jenkinsfile.

### Terraform

Terraform state is stored remotely in encrypted Amazon S3.

---

## Verification Results

The final platform verification confirmed that the application was healthy.

### Application Pods

```text
Backend replicas:
2/2 Running

Frontend replicas:
2/2 Running

MongoDB:
1/1 Running
```

Application pods had:

```text
0 restarts
```

### Backend

Backend logs confirmed:

```text
MongoDB connected
```

### Vault

Backend pods contained:

```text
backend
vault-agent
```

Both containers were ready.

### Helm

```text
Release:
cloudops-app

Status:
deployed

Revision:
7
```

### External Health Check

The external ALB health endpoint returned:

```json
{
  "status": "healthy",
  "service": "cloudops-backend"
}
```

### Monitoring

Prometheus successfully queried the Kubernetes monitoring targets.

Grafana successfully connected to the Prometheus datasource.

---

## Project Structure

```text
CloudOps-Platform/
│
├── app/
│   ├── backend/
│   └── frontend/
│
├── docs/
│   └── ARCHITECTURE.md
│
├── helm/
│   └── cloudops-app/
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

## Technology Stack

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
| Load Balancing         | AWS Application Load Balancer |
| Ingress                | AWS Load Balancer Controller  |
| Secrets                | HashiCorp Vault               |
| Monitoring             | Prometheus                    |
| Visualization          | Grafana                       |
| Application            | MERN                          |
| Backend                | Node.js / Express             |
| Frontend               | React                         |
| Database               | MongoDB                       |
| Storage                | Amazon EBS gp3                |
| Version Control        | Git / GitHub                  |

---

## Production Considerations

This project is designed as a cloud and DevOps portfolio platform and demonstrates production-style architecture.

Some components are intentionally simplified for learning and cost control.

### Vault

The current Vault deployment uses development-oriented storage.

A production environment should use:

* Persistent storage
* High availability
* Proper backup
* TLS
* Automated unsealing
* Production authentication and policies

### Grafana

Grafana persistence is disabled in the current environment.

A production deployment should use persistent storage for dashboards and configuration.

### EKS

The current cluster uses three `t3.small` nodes.

Production sizing should be based on:

* Workload requirements
* CPU and memory usage
* Pod density
* Availability requirements
* Autoscaling requirements
* Cost constraints

---

## End-to-End Platform Flow

The complete CloudOps Platform workflow is:

```text
Developer
   |
   v
GitHub
   |
   v
Jenkins CI/CD
   |
   +----> Test
   |
   +----> Build
   |
   +----> Docker
   |
   v
Docker Hub
   |
   v
Amazon EKS
   |
   +----> Helm
   |
   +----> Kubernetes
   |
   +----> Vault
   |
   +----> MongoDB
   |
   +----> AWS ALB
   |
   v
Application Users

                Monitoring
                    |
                    v
              Prometheus
                    |
                    v
                 Grafana
```

---

## Project Outcome

CloudOps Platform demonstrates an end-to-end cloud and DevOps workflow:

```text
Code
  ↓
Test
  ↓
Build
  ↓
Containerize
  ↓
Push
  ↓
Deploy
  ↓
Orchestrate
  ↓
Secure
  ↓
Monitor
```

The project brings together AWS, Terraform, Docker, Jenkins, Kubernetes, Amazon EKS, Helm, HashiCorp Vault, Prometheus, Grafana, and MongoDB into a single cloud-native platform.
