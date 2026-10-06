# Azure DevOps Platform Project

End-to-end Azure Cloud and DevOps project demonstrating:

- Microsoft Azure
- Terraform
- Docker
- Azure Container Registry
- Azure Kubernetes Service
- Kubernetes
- Helm
- GitHub Actions
- Azure Key Vault
- Managed Identity
- Azure Monitor
- Log Analytics
- KQL
- Autoscaling
- CI/CD
- Infrastructure as Code
- Monitoring
- Incident troubleshooting
- Rollback and recovery

## Architecture

Developer
   |
   v
GitHub
   |
   +---- Terraform ----> Azure Infrastructure
   |
   +---- CI -----------> Docker Build
                         |
                         v
                        ACR
                         |
                         v
                        AKS
                         |
                         v
                    Kubernetes Pods
                         |
                         v
                 Azure Monitor / KQL

## Application Endpoints

- `/`
- `/health`
- `/version`
- `/api/incidents`

## Project Status

Phase 1 - Project Setup
