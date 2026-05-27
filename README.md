# Serverless Microservices CI/CD Pipeline

A fully automated CI/CD pipeline for a containerized **Vue.js** and **Node.js/Express** microservices application, deployed on **AWS ECS Fargate** using **CloudFormation**, **CloudBuild**.



## Architecture Overview

The project follows a monorepo structure, deploying a standard To-Do List application through a serverless architecture to eliminate manual EC2 management.

* **Frontend**: Vue.js application served via Nginx.
* **Backend**: Node.js RESTful API handling task logic.
* **Infrastructure**: AWS Fargate (ECS) managed by an Application Load Balancer (ALB).
* **Routing**: The ALB handles path-based routing:
    * `/` → Frontend (Port 80)
    * `/task*` → Backend API (Port 3000)

## CI/CD Pipeline Workflow

The pipeline is defined in `pipeline.yml` using **AWS CodePipeline** and automates the following stages:

1.  **Source**: Triggers on GitHub commits.
2.  **DeployInfra**: Updates the ECS Cluster, ALB, and Task Definitions via CloudFormation.
3.  **Build (Bake)**: CodeBuild creates Docker images for both services and pushes them to **Amazon ECR**.
4.  **Deploy (Ship)**: ECS performs a **Rolling Update**, replacing old containers with zero downtime.
5.  **ScaleUp**: A post-deployment hook ensures the service capacity is adjusted to the desired task count.

---

## Repository Structure

```plaintext
├── frontend/             # Vue.js source code & Dockerfile
├── backend/              # Node.js API source code & Dockerfile
├── infra/
|   |-- 00-base/          # CodePipeline
│   ├── 01-codebuild/     # CloudFormation for ECR & Build Projects
│   ├── 02-ecs/           # CloudFormation for Cluster, ALB, & Fargate
│   ├── 03-scale/         # Scale-up logic & Buildspec
│   └── 99-iam/           # Global IAM Roles (Manual Pre-req)
└── buildspec.yml         # Shared build instructions for both services
```

## Technical Specifications

| Component | Technology | Port / Path |
| :--- | :--- | :--- |
| **Frontend** | Vue.js / Nginx | Port 80 / `/` |
| **Backend** | Node.js / Express | Port 3000 / `/task` |
| **Container Registry** | Amazon ECR | — |
| **Orchestration** | ECS Fargate | — |
| **CI/CD** | AWS CodePipeline | — |
| **Infrastructure** | CloudFormation | — |

---

## Prerequisites

Before deploying the pipeline, ensure the following requirements are met:

* **AWS CLI**: Must be configured with appropriate administrative permissions.
* **GitHub Token**: A Personal Access Token (PAT) with `repo` and `admin:repo_hook` scopes to allow CodePipeline to monitor your repository.
* **IAM Roles**: Manually execute the CloudFormation stacks in `infra/99-iam/` before the first run to establish global execution roles.