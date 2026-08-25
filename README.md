# Production-Grade Azure Infrastructure as Code

A production-oriented Azure DevOps/IaC project using **Terraform, Azure Kubernetes Service (AKS), Azure Container Registry (ACR), Docker, Kubernetes, and Helm**.

This project demonstrates the complete application delivery flow:

```text
Developer
   |
   v
Node.js Application
   |
   v
Docker Image
   |
   v
Azure Container Registry (ACR)
   |
   v
Azure Kubernetes Service (AKS)
   |
   +--> System Node Pool
   |      +--> CoreDNS
   |      +--> CSI
   |      +--> AKS system components
   |
   +--> User Node Pool
          +--> node-app
                 |
                 v
             Kubernetes Service
                 |
                 v
          Local Port Forward / Ingress
```

---

# 1. Project Goals

The goal of this project is to build and deploy a production-style Node.js application on Azure using Infrastructure as Code.

The project covers:

- Azure Resource Group
- Azure Container Registry
- Azure Kubernetes Service
- AKS system and user node pools
- Azure CNI Overlay networking
- Azure Network Policy
- Managed Identity
- ACR Pull permissions
- Docker image creation
- Docker image testing
- Helm application deployment
- Kubernetes Service
- Kubernetes health checks
- Kubernetes readiness checks
- Kubernetes resource requests and limits
- Kubernetes security context
- Non-root containers
- Helm upgrades
- Troubleshooting common AKS deployment issues

---

# 2. Prerequisites

Install the following tools on Windows.

## 2.1 Azure CLI

Verify:

```powershell
az version
```

Login:

```powershell
az login
```

Check subscription:

```powershell
az account show
```

If multiple subscriptions exist:

```powershell
az account list --output table
```

Select the required subscription:

```powershell
az account set --subscription "<SUBSCRIPTION_ID>"
```

Verify:

```powershell
az account show
```

---

## 2.2 Terraform

Verify:

```powershell
terraform version
```

Expected:

```text
Terraform v1.x.x
```

---

## 2.3 kubectl

Verify:

```powershell
kubectl version --client
```

---

## 2.4 Helm

Verify:

```powershell
helm version
```

If Helm is not recognized, install Helm and make sure its installation directory is present in the Windows `PATH`.

After changing PATH, restart PowerShell or VS Code.

Verify again:

```powershell
helm version
```

---

## 2.5 Docker

Verify:

```powershell
docker version
```

Verify Docker is running:

```powershell
docker info
```

---

# 3. Repository Structure

Recommended structure:

```text
production-grade-azure-iac/
│
├── app/
│   └── node-app/
│       ├── src/
│       │   └── server.js
│       ├── package.json
│       ├── package-lock.json
│       ├── Dockerfile
│       └── .dockerignore
│
├── helm/
│   └── node-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── serviceaccount.yaml
│           └── ...
│
├── modules/
│   ├── resource-group/
│   ├── container-registry/
│   └── aks/
│       ├── main.tf
│       └── variables.tf
│
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       └── outputs.tf
│
└── README.md
```

---

# 4. Clone the Repository

Clone the repository:

```powershell
git clone <REPOSITORY_URL>
```

Move into the project:

```powershell
cd production-grade-azure-iac
```

Verify:

```powershell
Get-ChildItem
```

---

# 5. Node.js Application

The application is located at:

```text
app/node-app
```

The application exposes:

```text
/health
/ready
```

These endpoints are used by Kubernetes probes.

Expected responses:

```json
{
  "status": "healthy"
}
```

and:

```json
{
  "status": "ready"
}
```

---

# 6. Install Node.js Dependencies

Move into the application directory:

```powershell
cd app/node-app
```

Verify `package.json` exists:

```powershell
Get-ChildItem
```

Install dependencies:

```powershell
npm install
```

## Important

If you see:

```text
npm : The term 'npm' is not recognized
```

Node.js is either not installed or is not available in PATH.

Check:

```powershell
node --version
npm --version
```

After installing Node.js, restart PowerShell/VS Code.

---

# 7. Test Node.js Application Locally

Start the application:

```powershell
npm start
```

Test:

```powershell
curl http://localhost:3000/health
```

Test readiness:

```powershell
curl http://localhost:3000/ready
```

Expected:

```text
200 OK
```

---

# 8. Dockerfile

The application Dockerfile follows a non-root container approach.

Example:

```dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev

COPY . .

RUN addgroup -S nodeapp && \
    adduser -S -u 10001 -G nodeapp nodeapp && \
    chown -R 10001:10001 /app

USER 10001

EXPOSE 3000

CMD ["node", "src/server.js"]
```

## Explanation

### Base image

```dockerfile
FROM node:22-alpine
```

Uses a lightweight Node.js Alpine image.

### Working directory

```dockerfile
WORKDIR /app
```

Application files are stored under `/app`.

### Dependency installation

```dockerfile
COPY package*.json ./
RUN npm ci --omit=dev
```

Installs production dependencies using the lock file.

### Application files

```dockerfile
COPY . .
```

Copies the application into the container.

### Non-root user

```dockerfile
RUN addgroup -S nodeapp && \
    adduser -S -u 10001 -G nodeapp nodeapp
```

Creates a non-root user.

### Run as non-root

```dockerfile
USER 10001
```

Improves container security.

### Application port

```dockerfile
EXPOSE 3000
```

Documents that the application listens on port 3000.

### Start command

```dockerfile
CMD ["node", "src/server.js"]
```

Starts the Node.js application.

---

# 9. Important Dockerfile Lesson

The actual application is located at:

```text
app/node-app/src/server.js
```

Therefore this is correct:

```dockerfile
CMD ["node", "src/server.js"]
```

This is incorrect unless `server.js` is copied to `/app`:

```dockerfile
CMD ["node", "server.js"]
```

If the wrong command is used, the container fails with:

```text
Error: Cannot find module '/app/server.js'
```

---

# 10. Build Docker Image

From:

```text
app/node-app
```

run:

```powershell
docker build -t node-app:1.0.0 .
```

Verify:

```powershell
docker images
```

---

# 11. Run Docker Container Locally

Run:

```powershell
docker run --rm -p 3000:3000 node-app:1.0.0
```

The application should be available at:

```text
http://localhost:3000
```

Test:

```powershell
curl http://localhost:3000/health
```

Expected:

```json
{"status":"healthy"}
```

Test:

```powershell
curl http://localhost:3000/ready
```

Expected:

```json
{"status":"ready"}
```

---

# 12. Azure Resource Group

Terraform creates the resource group.

Example:

```hcl
module "resource_group" {
  source = "../../modules/resource-group"

  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location

  tags = var.tags
}
```

Check the resource group:

```powershell
az group show --name rg-azure-iac-dev
```

---

# 13. Azure Container Registry

The ACR stores Docker images.

Example registry:

```text
acrazureiacdev01.azurecr.io
```

Check:

```powershell
az acr show \
  --name acrazureiacdev01 \
  --output table
```

Get login server:

```powershell
az acr show \
  --name acrazureiacdev01 \
  --query loginServer \
  --output tsv
```

Expected:

```text
acrazureiacdev01.azurecr.io
```

---

# 14. Authenticate Docker with ACR

Run:

```powershell
az acr login --name acrazureiacdev01
```

Expected:

```text
Login Succeeded
```

---

# 15. Tag Docker Image for ACR

Local image:

```text
node-app:1.0.0
```

ACR image:

```text
acrazureiacdev01.azurecr.io/node-app:1.0.0
```

Run:

```powershell
docker tag node-app:1.0.0 acrazureiacdev01.azurecr.io/node-app:1.0.0
```

---

# 16. Push Image to ACR

Run:

```powershell
docker push acrazureiacdev01.azurecr.io/node-app:1.0.0
```

Verify:

```powershell
az acr repository show-tags `
  --name acrazureiacdev01 `
  --repository node-app `
  --output table
```

Expected:

```text
1.0.0
```

---

# 17. Version Images Properly

Do not continuously overwrite `latest` for production deployments.

Use immutable versions:

```text
1.0.0
1.0.1
1.0.2
1.0.3
```

Example:

```powershell
docker build -t node-app:1.0.3 .
docker tag node-app:1.0.3 acrazureiacdev01.azurecr.io/node-app:1.0.3
docker push acrazureiacdev01.azurecr.io/node-app:1.0.3
```

Verify:

```powershell
az acr repository show-tags `
  --name acrazureiacdev01 `
  --repository node-app `
  --output table
```

---

# 18. AKS Architecture

The AKS cluster uses separate system and user workloads.

```text
AKS
│
├── System Node Pool
│   ├── CoreDNS
│   ├── CSI drivers
│   ├── kube-proxy
│   └── other critical AKS components
│
└── User Node Pool
    └── application workloads
        └── node-app
```

The system node pool is protected using:

```text
CriticalAddonsOnly=true:NoSchedule
```

This means normal application pods cannot be scheduled there.

---

# 19. Why the System Node Pool Taint Exists

Check:

```powershell
kubectl describe node <NODE_NAME> | Select-String "Taints"
```

You may see:

```text
Taints:
CriticalAddonsOnly=true:NoSchedule
```

This is intentional.

Do NOT manually remove it:

```powershell
kubectl taint nodes <NODE_NAME> CriticalAddonsOnly=true:NoSchedule-
```

AKS can reject this operation because the taint is managed by the AKS node pool configuration.

Instead, configure node pools through Terraform/Azure.

---

# 20. Terraform AKS Configuration

The system node pool should use:

```hcl
default_node_pool {
  name                         = "system"
  vm_size                      = var.vm_size
  node_count                   = 1
  only_critical_addons_enabled = true

  upgrade_settings {
    max_surge = "1"
  }
}
```

A dedicated user node pool should be configured for application workloads.

Example:

```hcl
node_pool {
  name                  = "user"
  vm_size               = var.vm_size
  node_count            = 1
  mode                  = "User"
  os_type               = "Linux"
  type                  = "VirtualMachineScaleSets"

  enable_auto_scaling = true
  min_count           = 1
  max_count           = 2

  upgrade_settings {
    max_surge = "1"
  }

  tags = var.tags
}
```

---

# 21. Terraform Initialize

Move to:

```powershell
cd environments/dev
```

Initialize:

```powershell
terraform init
```

Expected:

```text
Terraform has been successfully initialized!
```

---

# 22. Terraform Format

From the repository root:

```powershell
terraform fmt -recursive
```

---

# 23. Terraform Validate

Run:

```powershell
terraform validate
```

Expected:

```text
Success! The configuration is valid.
```

---

# 24. Terraform Plan

Always review the plan before applying:

```powershell
terraform plan
```

Check carefully for:

```text
0 to add
0 to destroy
```

or expected node-pool creation/update operations.

Never blindly apply a plan that proposes destroying the AKS cluster.

---

# 25. Terraform Apply

After reviewing the plan:

```powershell
terraform apply
```

Enter:

```text
yes
```

---

# 26. Verify AKS

Get credentials:

```powershell
az aks get-credentials `
  --resource-group rg-azure-iac-dev `
  --name aks-azure-iac-dev `
  --overwrite-existing
```

Check cluster:

```powershell
kubectl get nodes
```

Expected architecture after user pool creation:

```text
NAME                              STATUS   ROLES
aks-system-...                   Ready    <none>
aks-user-...                     Ready    <none>
```

---

# 27. Check Node Pool Labels

Run:

```powershell
kubectl get nodes --show-labels
```

Look for:

```text
kubernetes.azure.com/agentpool=system
```

and:

```text
kubernetes.azure.com/agentpool=user
```

---

# 28. Helm

Check Helm:

```powershell
helm version
```

Validate the chart:

```powershell
helm lint .\helm\node-app
```

Expected:

```text
1 chart(s) linted, 0 chart(s) failed
```

---

# 29. Helm Values

The image should be configurable through `values.yaml`.

Example:

```yaml
image:
  repository: acrazureiacdev01.azurecr.io/node-app
  tag: "1.0.3"
  pullPolicy: IfNotPresent
```

This allows changing the application version without modifying the Deployment template.

---

# 30. Schedule Application on User Node Pool

Add the user node-pool selector to the Helm Deployment:

```yaml
nodeSelector:
  kubernetes.azure.com/agentpool: user
```

This ensures:

```text
node-app
   |
   v
user node pool
```

instead of the system node pool.

---

# 31. Kubernetes Resource Requests and Limits

Example:

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi

  limits:
    cpu: 250m
    memory: 256Mi
```

Requests determine the minimum resources Kubernetes reserves for scheduling.

Limits define the maximum resources the container can consume.

---

# 32. Kubernetes Health Probes

## Startup Probe

```yaml
startupProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 0
  periodSeconds: 5
  failureThreshold: 30
```

Used while the application is starting.

---

## Readiness Probe

```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: http
  initialDelaySeconds: 5
  periodSeconds: 10
```

Controls whether the pod receives Service traffic.

---

## Liveness Probe

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: http
  initialDelaySeconds: 15
  periodSeconds: 20
```

Detects an unhealthy application and allows Kubernetes to restart it.

---

# 33. Kubernetes Security Context

The container should run as a non-root user.

Example:

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 10001
  allowPrivilegeEscalation: false
```

This works together with the Dockerfile:

```dockerfile
USER 10001
```

---

# 34. Important `runAsNonRoot` Issue

If the Docker image specifies:

```dockerfile
USER nodeapp
```

Kubernetes may produce:

```text
container has runAsNonRoot and image has non-numeric user (nodeapp)
```

A robust solution is to use a numeric UID:

```dockerfile
USER 10001
```

and:

```yaml
runAsUser: 10001
```

---

# 35. Deploy Using Helm

Create namespace if required:

```powershell
kubectl create namespace node-app
```

Install:

```powershell
helm install node-app .\helm\node-app -n node-app
```

Or upgrade:

```powershell
helm upgrade node-app .\helm\node-app -n node-app
```

Check:

```powershell
helm list -n node-app
```

---

# 36. Check Pods

Run:

```powershell
kubectl get pods -n node-app
```

Expected:

```text
NAME                         READY   STATUS
node-app-xxxxxxxxxx          1/1     Running
```

Watch:

```powershell
kubectl get pods -n node-app -w
```

---

# 37. Check Pod Details

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Verify:

```text
Status: Running
Ready: True
Image: acrazureiacdev01.azurecr.io/node-app:1.0.3
```

---

# 38. Verify Pod Node

```powershell
kubectl get pod -n node-app -o wide
```

The application should show the user node:

```text
NODE
aks-user-...
```

This confirms the application is not running on the system pool.

---

# 39. Check Logs

```powershell
kubectl logs -n node-app <POD_NAME>
```

For a previous crashed container:

```powershell
kubectl logs -n node-app <POD_NAME> --previous
```

---

# 40. Check Service

```powershell
kubectl get svc -n node-app
```

Example:

```text
NAME       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
node-app   ClusterIP   10.x.x.x        <none>        80/TCP
```

The Service can expose port 80 while forwarding to application port 3000.

Example:

```yaml
ports:
  - port: 80
    targetPort: 3000
```

Traffic flow:

```text
Service :80
    |
    v
Pod :3000
```

---

# 41. Check Endpoints

Use:

```powershell
kubectl get endpoints -n node-app
```

You may see a deprecation warning on modern Kubernetes versions.

Prefer:

```powershell
kubectl get endpointslice -n node-app
```

Expected:

```text
ENDPOINTS
10.244.x.x
```

If there are no endpoints:

```text
ENDPOINTS <none>
```

check:

```powershell
kubectl get pods -n node-app
kubectl describe pod -n node-app <POD_NAME>
kubectl describe svc -n node-app node-app
```

Usually this means the Service selector does not match a Ready pod.

---

# 42. Test the Service Using Port Forwarding

Because the Service exposes port 80:

```powershell
kubectl port-forward -n node-app svc/node-app 3000:80
```

Expected:

```text
Forwarding from 127.0.0.1:3000 -> 3000
```

Keep this terminal running.

Open another PowerShell terminal.

---

# 43. Test `/health`

```powershell
curl.exe http://localhost:3000/health
```

Expected:

```json
{"status":"healthy"}
```

Using `curl.exe` avoids PowerShell's alias behavior.

---

# 44. Test `/ready`

```powershell
curl.exe http://localhost:3000/ready
```

Expected:

```json
{"status":"ready"}
```

---

# 45. Test Service From Inside Kubernetes

You can create a temporary curl/wget pod:

```powershell
kubectl run test-client `
  --rm -it `
  --restart=Never `
  --image=curlimages/curl `
  -- http://node-app.node-app.svc.cluster.local/health
```

Expected:

```json
{"status":"healthy"}
```

This verifies Kubernetes internal DNS and Service routing.

---

# 46. Troubleshooting: Pod Pending

Check:

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Look at:

```text
Events:
```

If you see:

```text
untolerated taint
CriticalAddonsOnly=true:NoSchedule
```

the application is trying to run on the system pool.

Fix by scheduling the workload on the user pool:

```yaml
nodeSelector:
  kubernetes.azure.com/agentpool: user
```

---

# 47. Troubleshooting: ImagePullBackOff

Check:

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Look for:

```text
Failed to pull image
```

Verify image exists:

```powershell
az acr repository show-tags `
  --name acrazureiacdev01 `
  --repository node-app `
  --output table
```

Verify ACR Pull permission:

```powershell
az role assignment list `
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-azure-iac-dev/providers/Microsoft.ContainerRegistry/registries/acrazureiacdev01" `
  --role AcrPull `
  --output table
```

The AKS kubelet identity should have:

```text
AcrPull
```

---

# 48. Troubleshooting: ACR Repository Not Found

If:

```powershell
az acr repository show-tags `
  --name acrazureiacdev01 `
  --repository node-app
```

returns:

```text
repository "node-app" is not found
```

then the image was not pushed to that registry/repository.

Push again:

```powershell
docker tag node-app:1.0.3 acrazureiacdev01.azurecr.io/node-app:1.0.3

docker push acrazureiacdev01.azurecr.io/node-app:1.0.3
```

Then verify again.

---

# 49. Troubleshooting: CreateContainerConfigError

Check:

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Look for configuration/security errors.

For example:

```text
container has runAsNonRoot and image has non-numeric user
```

Use a numeric UID in the Dockerfile:

```dockerfile
USER 10001
```

and Kubernetes:

```yaml
runAsUser: 10001
runAsNonRoot: true
```

---

# 50. Troubleshooting: CrashLoopBackOff

First check logs:

```powershell
kubectl logs -n node-app <POD_NAME>
```

If the container restarted:

```powershell
kubectl logs -n node-app <POD_NAME> --previous
```

If you see:

```text
Cannot find module '/app/server.js'
```

verify:

```powershell
Get-ChildItem .\app\node-app\src
```

If the application is:

```text
src/server.js
```

the Dockerfile must use:

```dockerfile
CMD ["node", "src/server.js"]
```

---

# 51. Troubleshooting: Startup Probe Failed

Example:

```text
Startup probe failed:
connect: connection refused
```

First check:

```powershell
kubectl logs -n node-app <POD_NAME>
```

Then verify that the Node.js application is listening on:

```text
0.0.0.0:3000
```

and not only:

```text
localhost:3000
```

The application should listen on all interfaces inside the container.

---

# 52. Troubleshooting: Service Has No Endpoints

Check:

```powershell
kubectl get endpointslice -n node-app
```

If:

```text
ENDPOINTS <none>
```

check pod labels:

```powershell
kubectl get pods -n node-app --show-labels
```

Check Service:

```powershell
kubectl describe svc -n node-app node-app
```

The Service selector must match the pod labels.

Also verify:

```powershell
kubectl get pods -n node-app
```

The pod must be:

```text
READY 1/1
```

A pod failing its readiness probe is normally excluded from Service endpoints.

---

# 53. Helm Upgrade Workflow

Build a new version:

```powershell
docker build -t node-app:1.0.4 .
```

Tag:

```powershell
docker tag node-app:1.0.4 `
  acrazureiacdev01.azurecr.io/node-app:1.0.4
```

Push:

```powershell
docker push `
  acrazureiacdev01.azurecr.io/node-app:1.0.4
```

Update Helm values:

```yaml
image:
  repository: acrazureiacdev01.azurecr.io/node-app
  tag: "1.0.4"
```

Validate:

```powershell
helm lint .\helm\node-app
```

Upgrade:

```powershell
helm upgrade node-app .\helm\node-app -n node-app
```

Watch rollout:

```powershell
kubectl rollout status deployment/node-app -n node-app
```

Check:

```powershell
kubectl get pods -n node-app
```

---

# 54. Helm Rollback

List releases:

```powershell
helm history node-app -n node-app
```

Rollback:

```powershell
helm rollback node-app <REVISION> -n node-app
```

Verify:

```powershell
kubectl rollout status deployment/node-app -n node-app
```

---

# 55. Kubernetes Rollout

Check:

```powershell
kubectl rollout status deployment/node-app -n node-app
```

Check history:

```powershell
kubectl rollout history deployment/node-app -n node-app
```

Restart:

```powershell
kubectl rollout restart deployment/node-app -n node-app
```

---

# 56. Useful Daily Commands

## Azure

```powershell
az account show
az group list --output table
az aks list --output table
az acr list --output table
```

## Terraform

```powershell
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
terraform output
terraform state list
```

## Docker

```powershell
docker images
docker ps
docker ps -a
docker logs <CONTAINER>
docker build -t node-app:1.0.0 .
docker run --rm -p 3000:3000 node-app:1.0.0
```

## ACR

```powershell
az acr show --name acrazureiacdev01
az acr repository list --name acrazureiacdev01 --output table
az acr repository show-tags --name acrazureiacdev01 --repository node-app --output table
```

## AKS

```powershell
kubectl get nodes
kubectl get pods -A
kubectl get pods -n node-app
kubectl get svc -n node-app
kubectl get endpointslice -n node-app
kubectl get events -n node-app --sort-by=.lastTimestamp
```

## Helm

```powershell
helm list -n node-app
helm lint .\helm\node-app
helm history node-app -n node-app
helm upgrade node-app .\helm\node-app -n node-app
```

---

# 57. Recommended Deployment Sequence

Use this sequence whenever deploying a new version:

```text
1. Modify application
       |
       v
2. Test locally
       |
       v
3. Build Docker image
       |
       v
4. Test Docker container
       |
       v
5. Tag image
       |
       v
6. Push image to ACR
       |
       v
7. Update Helm image tag
       |
       v
8. helm lint
       |
       v
9. helm upgrade
       |
       v
10. Check rollout
       |
       v
11. Check pod
       |
       v
12. Check endpoints
       |
       v
13. Test /health
       |
       v
14. Test /ready
```

---

# 58. Production Readiness Checklist

Before considering the project production-ready:

- [ ] Remote Terraform state configured
- [ ] State locking configured
- [ ] Separate dev/stage/prod environments
- [ ] Separate AKS system/user node pools
- [ ] AKS autoscaling enabled
- [ ] Pod resource requests configured
- [ ] Pod resource limits configured
- [ ] Startup probe configured
- [ ] Readiness probe configured
- [ ] Liveness probe configured
- [ ] Container runs as non-root
- [ ] ACR Pull uses managed identity
- [ ] Image versions are immutable
- [ ] No secrets committed to Git
- [ ] Kubernetes Secrets/Key Vault used for secrets
- [ ] Helm values separated by environment
- [ ] Rolling update strategy configured
- [ ] PodDisruptionBudget considered
- [ ] Network policies configured
- [ ] Ingress configured
- [ ] HTTPS/TLS configured
- [ ] Monitoring enabled
- [ ] Logging enabled
- [ ] Alerts configured
- [ ] CI/CD pipeline configured
- [ ] Backup/DR strategy documented

---

# 59. Future Enhancements

The next phases of this project should include:

## Phase 1 — Kubernetes Networking

```text
Ingress
   |
   v
Service
   |
   v
Pod
```

Add:

- NGINX Ingress
- Public IP
- DNS
- TLS

## Phase 2 — Autoscaling

Add:

- AKS cluster autoscaler
- Horizontal Pod Autoscaler
- CPU/memory-based scaling

## Phase 3 — Secrets

Integrate:

```text
Azure Key Vault
       |
       v
AKS Workload Identity
       |
       v
Application
```

## Phase 4 — CI/CD

Recommended flow:

```text
Git Push
   |
   v
GitHub Actions
   |
   +--> Test
   |
   +--> Docker Build
   |
   +--> Push to ACR
   |
   +--> Helm Upgrade
   |
   v
AKS
```

## Phase 5 — Observability

Add:

- Azure Monitor
- Container Insights
- Prometheus
- Grafana
- Application logs
- Alerts

---

# 60. Git Workflow

Create a feature branch:

```powershell
git checkout -b feature/aks-user-nodepool
```

Check changes:

```powershell
git status
```

Review:

```powershell
git diff
```

Add:

```powershell
git add .
```

Commit:

```powershell
git commit -m "feat: add dedicated AKS user node pool"
```

Push:

```powershell
git push -u origin feature/aks-user-nodepool
```

Create an MR/PR.

---

# 61. MR Title

Recommended:

```text
Add dedicated AKS user node pool for application workloads
```

## MR Summary

This change separates AKS system components from application workloads by introducing a dedicated user node pool. The system node pool is reserved for critical AKS components, while application workloads such as `node-app` are scheduled onto the user node pool.

---

# 62. Key Interview Concepts Demonstrated

This project can be used to explain the following in DevOps interviews:

### Terraform

- Modules
- Variables
- Outputs
- Environments
- State
- Plan vs Apply
- Infrastructure lifecycle
- AzureRM provider

### Azure

- Resource Groups
- ACR
- AKS
- Managed Identity
- RBAC
- ACR Pull
- Azure networking

### Kubernetes

- Pods
- Deployments
- Services
- EndpointSlices
- Node pools
- Taints and tolerations
- Node selectors
- Resource requests/limits
- Probes
- Security contexts

### Helm

- Charts
- Values
- Templates
- Releases
- Upgrades
- Rollbacks

### Docker

- Multi-stage/container optimization concepts
- Non-root containers
- Image tagging
- Registry push/pull
- Container health

---

# 63. Final Architecture

The target production architecture is:

```text
                         Internet
                            |
                            v
                    +---------------+
                    |    Ingress    |
                    |  HTTPS / TLS  |
                    +-------+-------+
                            |
                            v
                    +---------------+
                    | Kubernetes    |
                    |   Service     |
                    +-------+-------+
                            |
                            v
                 +----------------------+
                 |      AKS Cluster     |
                 |                      |
                 |  +----------------+  |
                 |  | System Pool    |  |
                 |  |                |  |
                 |  | Critical AKS   |  |
                 |  | Components     |  |
                 |  +----------------+  |
                 |                      |
                 |  +----------------+  |
                 |  | User Pool      |  |
                 |  |                |  |
                 |  | node-app       |  |
                 |  | replicas       |  |
                 |  +----------------+  |
                 +----------+-----------+
                            |
                            |
                     Managed Identity
                            |
                            v
                    +---------------+
                    |      ACR      |
                    |               |
                    | node-app:1.x  |
                    +---------------+

Terraform manages:
    Resource Group
    ACR
    AKS
    Node Pools
    RBAC
    Networking
    Identity
```

---

# 64. Conclusion

This repository demonstrates a complete Azure cloud-native deployment workflow using Infrastructure as Code.

The application lifecycle is:

```text
Code
  ↓
Node.js
  ↓
Docker
  ↓
ACR
  ↓
AKS
  ↓
Helm
  ↓
Deployment
  ↓
Pod
  ↓
Service
  ↓
Ingress
  ↓
User
```

The infrastructure lifecycle is:

```text
Terraform
    ↓
Azure Resource Group
    ↓
ACR
    ↓
AKS
    ↓
System Node Pool
    +
User Node Pool
```

The project is designed to progressively evolve toward a production-grade platform with CI/CD, autoscaling, ingress, TLS, Key Vault, monitoring, logging, and disaster recovery.


---

# 20. Architecture Diagram

The final development architecture is conceptually:

```text
                         Developer Laptop
                               |
                    +----------+----------+
                    |                     |
                 Terraform               Helm
                    |                     |
                    v                     v
             +-------------+       +-------------+
             | Azure RG    |       | AKS Cluster |
             |             |       |             |
             | ACR         |<------+| System Pool |
             +------+------+       |             |
                    ^              | node-app    |
                    |              | Deployment  |
                 docker push       | Service     |
                    |              +------+------+
                    |                     |
              +-----+-----+               |
              | Local     |               |
              | Docker    |               |
              | node-app  |               |
              +-----------+               |
                                          v
                                   Pod :3000
                                          |
                                   ClusterIP :80
```

## Request flow

```text
Client
  |
  | HTTP
  v
Kubernetes Service
node-app:80
  |
  | targetPort: 3000
  v
node-app Pod
  |
  +--> /health
  |
  +--> /ready
```

---

# 21. Complete Deployment Flow

For a new developer joining the project, the complete flow is:

```text
1. Clone repository
       |
       v
2. Install Azure CLI / Terraform / Docker / kubectl / Helm
       |
       v
3. Login to Azure
       |
       v
4. Create/validate Resource Group
       |
       v
5. Terraform init
       |
       v
6. Terraform plan
       |
       v
7. Terraform apply
       |
       v
8. AKS + ACR created
       |
       v
9. ACR AcrPull assigned to AKS kubelet identity
       |
       v
10. Build Node.js application
       |
       v
11. Build Docker image
       |
       v
12. Test Docker container locally
       |
       v
13. Login to ACR
       |
       v
14. Push image to ACR
       |
       v
15. Get AKS credentials
       |
       v
16. Validate Kubernetes node
       |
       v
17. Deploy application using Helm
       |
       v
18. Verify Pod
       |
       v
19. Verify Service
       |
       v
20. Verify EndpointSlice
       |
       v
21. Port-forward Service
       |
       v
22. Test /health and /ready
```

---

# 22. Exact Commands - End-to-End

## Step 1 - Navigate to project

```powershell
cd D:\azure_workspace\production-grade-azure-iac
```

## Step 2 - Verify tools

```powershell
az version
terraform version
docker --version
kubectl version --client
helm version
node --version
npm --version
```

## Step 3 - Login to Azure

```powershell
az login
```

Verify subscription:

```powershell
az account show
```

If required:

```powershell
az account set --subscription "<SUBSCRIPTION_ID>"
```

---

# 23. Terraform Deployment

Move into the environment:

```powershell
cd .\environments\dev
```

Initialize Terraform:

```powershell
terraform init
```

Validate configuration:

```powershell
terraform validate
```

Format Terraform:

```powershell
terraform fmt -recursive
```

Review the plan:

```powershell
terraform plan
```

Apply:

```powershell
terraform apply
```

Verify:

```powershell
terraform output
```

---

# 24. Verify Azure Resources

List resource groups:

```powershell
az group list --output table
```

List resources:

```powershell
az resource list `
  --resource-group rg-azure-iac-dev `
  --output table
```

Verify AKS:

```powershell
az aks show `
  --resource-group rg-azure-iac-dev `
  --name aks-azure-iac-dev `
  --output table
```

Verify ACR:

```powershell
az acr show `
  --name acrazureiacdev01 `
  --output table
```

---

# 25. Verify AKS → ACR Permission

Get kubelet identity:

```powershell
az aks show `
  --resource-group rg-azure-iac-dev `
  --name aks-azure-iac-dev `
  --query identityProfile.kubeletidentity.clientId `
  --output tsv
```

Check AcrPull:

```powershell
az role assignment list `
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-azure-iac-dev/providers/Microsoft.ContainerRegistry/registries/acrazureiacdev01" `
  --role AcrPull `
  --output table
```

Expected:

```text
Principal                             Role
------------------------------------  -------
<kubelet-client-id>                   AcrPull
```

This permission allows the AKS node identity to pull private images from ACR.

---

# 26. Node.js Application

Application structure:

```text
app/
└── node-app/
    ├── src/
    │   └── server.js
    ├── package.json
    ├── package-lock.json
    ├── Dockerfile
    └── .dockerignore
```

Install dependencies:

```powershell
cd .\app\node-app
npm install
```

Run locally:

```powershell
npm start
```

Test:

```powershell
curl.exe http://localhost:3000/health
curl.exe http://localhost:3000/ready
```

Expected:

```json
{"status":"healthy"}
```

and:

```json
{"status":"ready"}
```

---

# 27. Docker Build and Test

Build:

```powershell
docker build -t node-app:1.0.3 .
```

Run:

```powershell
docker run --rm -p 3000:3000 node-app:1.0.3
```

Test from another terminal:

```powershell
curl.exe http://localhost:3000/health
```

Test readiness:

```powershell
curl.exe http://localhost:3000/ready
```

Check container:

```powershell
docker ps
```

---

# 28. Login to Azure Container Registry

```powershell
az acr login --name acrazureiacdev01
```

Tag:

```powershell
docker tag node-app:1.0.3 acrazureiacdev01.azurecr.io/node-app:1.0.3
```

Push:

```powershell
docker push acrazureiacdev01.azurecr.io/node-app:1.0.3
```

Verify:

```powershell
az acr repository show-tags `
  --name acrazureiacdev01 `
  --repository node-app `
  --output table
```

Expected:

```text
Result
------
1.0.0
1.0.1
1.0.2
1.0.3
```

---

# 29. Connect kubectl to AKS

```powershell
az aks get-credentials `
  --resource-group rg-azure-iac-dev `
  --name aks-azure-iac-dev `
  --overwrite-existing
```

Verify:

```powershell
kubectl get nodes
```

Example:

```text
NAME                             STATUS   ROLES
aks-system-xxxx-vmss000000      Ready    <none>
```

---

# 30. Check AKS Node Taints

```powershell
kubectl describe node <NODE_NAME> | Select-String "Taints"
```

For a system node pool, you may see:

```text
Taints:
CriticalAddonsOnly=true:NoSchedule
```

Do **not** manually remove an AKS-managed system-pool taint.

If this taint is present, normal workloads should be deployed to a user node pool.

Recommended architecture:

```text
AKS
├── system node pool
│   └── Kubernetes/Azure system workloads
│
└── user node pool
    └── application workloads
```

---

# 31. Create a User Node Pool

For production-style architecture, create a dedicated user node pool.

Example Azure CLI:

```powershell
az aks nodepool add `
  --resource-group rg-azure-iac-dev `
  --cluster-name aks-azure-iac-dev `
  --name user `
  --node-count 1 `
  --node-vm-size Standard_B2s_v2 `
  --mode User
```

Verify:

```powershell
kubectl get nodes -L agentpool
```

Expected conceptually:

```text
NAME                         STATUS   AGENTPOOL
aks-system-xxxx-vmss000000   Ready    system
aks-user-xxxx-vmss000000     Ready    user
```

Then application pods can be targeted to the user pool.

---

# 32. Helm Deployment

Go to project root:

```powershell
cd D:\azure_workspace\production-grade-azure-iac
```

Lint:

```powershell
helm lint .\helm\node-app
```

Install:

```powershell
helm install node-app .\helm\node-app -n node-app --create-namespace
```

Or upgrade:

```powershell
helm upgrade node-app .\helm\node-app -n node-app
```

Verify:

```powershell
helm list -n node-app
```

---

# 33. Kubernetes Verification

Check Pods:

```powershell
kubectl get pods -n node-app
```

Watch:

```powershell
kubectl get pods -n node-app -w
```

Expected:

```text
NAME                       READY   STATUS
node-app-xxxxx             1/1     Running
```

Check deployment:

```powershell
kubectl get deployment -n node-app
```

Check ReplicaSet:

```powershell
kubectl get rs -n node-app
```

Check service:

```powershell
kubectl get svc -n node-app
```

Expected:

```text
NAME       TYPE        CLUSTER-IP       PORT(S)
node-app   ClusterIP   10.x.x.x         80/TCP
```

---

# 34. Verify EndpointSlice

Use EndpointSlice rather than the deprecated Endpoints API:

```powershell
kubectl get endpointslice -n node-app
```

Expected:

```text
NAME             ADDRESS TYPE   PORTS   ENDPOINTS
node-app-xxxxx   IPv4           3000    10.244.x.x
```

Detailed:

```powershell
kubectl describe endpointslice -n node-app
```

If you see:

```text
Endpoints: <none>
```

check:

```powershell
kubectl get pods -n node-app --show-labels
kubectl get svc node-app -n node-app -o yaml
```

The Service selector must match the Pod labels.

---

# 35. Port Forward the Service

The application listens on:

```text
Pod/container: 3000
```

The Kubernetes Service exposes:

```text
Service: 80
```

Therefore:

```powershell
kubectl port-forward -n node-app svc/node-app 3000:80
```

Do not use:

```powershell
kubectl port-forward -n node-app svc/node-app 3000:3000
```

if the Service exposes only port `80`.

You should see:

```text
Forwarding from 127.0.0.1:3000 -> 3000
```

---

# 36. Test the Application

In another PowerShell window:

```powershell
curl.exe http://localhost:3000/health
```

Expected:

```json
{"status":"healthy"}
```

Readiness:

```powershell
curl.exe http://localhost:3000/ready
```

Expected:

```json
{"status":"ready"}
```

Using PowerShell's `curl` alias can invoke `Invoke-WebRequest`. To avoid the PowerShell warning, prefer:

```powershell
curl.exe http://localhost:3000/health
```

or:

```powershell
Invoke-WebRequest http://localhost:3000/health -UseBasicParsing
```

---

# 37. Verify Kubernetes Probes

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

You should see:

```text
Liveness:
  http-get /health

Readiness:
  http-get /ready

Startup:
  http-get /health
```

Meaning:

### Startup probe

Determines whether the application has successfully started.

### Readiness probe

Determines whether the Pod can receive traffic.

### Liveness probe

Determines whether the application is still healthy.

---

# 38. Important Dockerfile Lesson

The application source is located here:

```text
src/server.js
```

Therefore this is incorrect:

```dockerfile
CMD ["node", "server.js"]
```

unless `server.js` exists directly under `/app`.

The correct command for the current project structure is:

```dockerfile
CMD ["node", "src/server.js"]
```

This issue previously caused:

```text
Error: Cannot find module '/app/server.js'
```

After changing the Dockerfile, rebuild and push a new immutable image tag.

Example:

```powershell
docker build -t node-app:1.0.3 .
docker tag node-app:1.0.3 acrazureiacdev01.azurecr.io/node-app:1.0.3
docker push acrazureiacdev01.azurecr.io/node-app:1.0.3
```

Then update Helm:

```yaml
image:
  repository: acrazureiacdev01.azurecr.io/node-app
  tag: "1.0.3"
```

Deploy:

```powershell
helm upgrade node-app .\helm\node-app -n node-app
```

---

# 39. Troubleshooting Decision Tree

## Pod Pending

Run:

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Look at:

```text
Events:
```

If you see:

```text
had untolerated taint
```

check:

```powershell
kubectl describe nodes
```

Likely solution:

```text
Deploy application workloads to a user node pool.
```

---

## ImagePullBackOff

Run:

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Check the image:

```text
acrazureiacdev01.azurecr.io/node-app:1.0.3
```

Verify ACR:

```powershell
az acr repository show-tags `
  --name acrazureiacdev01 `
  --repository node-app `
  --output table
```

Verify AcrPull:

```powershell
az role assignment list `
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-azure-iac-dev/providers/Microsoft.ContainerRegistry/registries/acrazureiacdev01" `
  --role AcrPull `
  --output table
```

---

## CreateContainerConfigError

Run:

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Look for security-context errors.

For example:

```text
container has runAsNonRoot and image has non-numeric user
```

A robust Dockerfile should use a numeric UID:

```dockerfile
USER 10001
```

and Kubernetes can safely use:

```yaml
runAsNonRoot: true
runAsUser: 10001
```

---

## CrashLoopBackOff

Run:

```powershell
kubectl logs -n node-app <POD_NAME>
```

Previous container:

```powershell
kubectl logs -n node-app <POD_NAME> --previous
```

If you see:

```text
Cannot find module '/app/server.js'
```

check:

```powershell
Get-ChildItem .\app\node-app
Get-ChildItem .\app\node-app\src
```

Then correct the Docker `CMD`.

---

## Startup probe failure

Example:

```text
Startup probe failed:
connect: connection refused
```

Check logs:

```powershell
kubectl logs -n node-app <POD_NAME>
```

Check the application port:

```text
PORT=3000
```

Check Docker:

```powershell
docker run --rm -p 3000:3000 <IMAGE>
```

Check endpoint:

```powershell
curl.exe http://localhost:3000/health
```

---

## Service has no endpoints

Run:

```powershell
kubectl get endpointslice -n node-app
```

Then:

```powershell
kubectl get pods -n node-app --show-labels
```

and:

```powershell
kubectl get svc node-app -n node-app -o yaml
```

Verify Service selectors match Pod labels.

---

# 40. Terraform AKS Node-Pool Rotation

AKS default node-pool properties cannot always be modified directly.

Terraform may return:

```text
temporary_name_for_rotation must be specified
```

For properties requiring node-pool rotation, configure:

```hcl
temporary_name_for_rotation = "systemtmp"
```

Example:

```hcl
default_node_pool {
  name                         = "system"
  vm_size                      = "Standard_B2s_v2"
  node_count                   = 1
  only_critical_addons_enabled = false

  temporary_name_for_rotation = "systemtmp"

  upgrade_settings {
    max_surge = "1"
  }
}
```

The important point is that `temporary_name_for_rotation` belongs **inside `default_node_pool`**, not as a top-level AKS attribute.

---

# 41. Recommended Git Workflow

Create a feature branch:

```powershell
git checkout -b feature/production-azure-iac
```

Check:

```powershell
git status
```

Stage:

```powershell
git add .
```

Commit:

```powershell
git commit -m "feat: deploy node app on AKS using Terraform and Helm"
```

Push:

```powershell
git push origin feature/production-azure-iac
```

Then create the MR/PR.

---

# 42. Suggested MR Title

```text
feat: implement production-grade Azure AKS infrastructure with Terraform and Helm
```

Alternative:

```text
feat: deploy containerized Node.js app to AKS using Terraform, ACR and Helm
```

---

# 43. Suggested MR Description

```markdown
## Summary

Implemented production-grade Azure infrastructure using Terraform and deployed a containerized Node.js application to Azure Kubernetes Service using Helm.

## What was implemented

- Azure Resource Group
- Azure Container Registry
- Azure Kubernetes Service
- AKS managed identity
- AKS → ACR AcrPull role assignment
- Azure CNI Overlay networking
- Azure network policy
- OIDC issuer
- Workload Identity
- Kubernetes RBAC
- Node.js application
- Multi-stage/security-focused container configuration
- Non-root container execution
- Docker health endpoints
- Kubernetes startup probe
- Kubernetes readiness probe
- Kubernetes liveness probe
- Kubernetes Service
- Helm chart
- ACR image versioning
- End-to-end AKS deployment and validation

## Validation

Verified:

- Docker image runs successfully
- Docker container health endpoint
- ACR image push
- AKS node readiness
- AKS → ACR image pull
- Kubernetes Pod scheduling
- Pod readiness
- Service creation
- EndpointSlice registration
- Helm deployment
- `/health` endpoint
- `/ready` endpoint
- Container restart behavior

## Troubleshooting completed

Resolved:

- npm PATH issue
- Missing package.json
- AKS system-node taint scheduling issue
- Terraform AKS node-pool rotation requirement
- ACR image pull authorization
- non-root container security-context issue
- incorrect Node.js application path in Dockerfile
- CrashLoopBackOff
- startup probe failures
- Kubernetes Service port mapping

## Deployment

Application is deployed using:

- Terraform for Azure infrastructure
- Docker for containerization
- ACR for image storage
- AKS for Kubernetes runtime
- Helm for application deployment

## Future Improvements

- Dedicated AKS user node pool
- Horizontal Pod Autoscaler
- PodDisruptionBudget
- NetworkPolicy hardening
- Azure Key Vault integration
- Workload Identity
- Ingress/Application Gateway
- TLS
- Azure Monitor
- Prometheus/Grafana
- CI/CD with GitHub Actions or Azure DevOps
- Terraform remote state
- Environment promotion: dev → staging → production
```

---

# 44. Production Hardening Checklist

Before calling this production-ready, implement:

## Infrastructure

- [ ] Terraform remote state
- [ ] State locking
- [ ] Separate environments
- [ ] Azure resource locks where appropriate
- [ ] Resource tagging
- [ ] Azure Budget alerts
- [ ] Log Analytics
- [ ] Azure Monitor

## AKS

- [ ] Dedicated system node pool
- [ ] Dedicated user node pool
- [ ] Multiple nodes for production
- [ ] Availability Zones
- [ ] Autoscaling
- [ ] Pod disruption budgets
- [ ] Network policies
- [ ] Private cluster where required
- [ ] API server authorized IP ranges where appropriate

## Application

- [ ] Non-root container
- [ ] Readiness probe
- [ ] Liveness probe
- [ ] Startup probe
- [ ] CPU requests/limits
- [ ] Memory requests/limits
- [ ] Immutable image tags
- [ ] Image vulnerability scanning
- [ ] SBOM
- [ ] Dependency scanning

## Security

- [ ] Workload Identity
- [ ] Azure Key Vault
- [ ] Secrets not stored in Git
- [ ] Least-privilege RBAC
- [ ] ACR private access where required
- [ ] Network segmentation

## CI/CD

- [ ] Automated Docker build
- [ ] Automated image scan
- [ ] Automated ACR push
- [ ] Helm deployment
- [ ] Automated smoke tests
- [ ] Rollback strategy
- [ ] Git-based environment promotion

---

# 45. Interview Explanation

A concise explanation of this project:

> "I built a production-oriented Azure infrastructure using Terraform. The infrastructure provisions a Resource Group, Azure Container Registry and AKS. The AKS cluster uses managed identity, Azure CNI Overlay networking, Azure network policy, RBAC, OIDC and Workload Identity. The Node.js application is containerized using Docker and stored in ACR. The AKS kubelet identity is granted AcrPull access to the registry, allowing Kubernetes to pull private images without storing registry credentials in the application manifest. The application is deployed through a Helm chart with resource requests/limits and startup, readiness and liveness probes. I validated the complete flow from local Docker execution through ACR, AKS scheduling, image pulling, Kubernetes Service discovery and application health endpoints."

---

# 46. Key Architecture Lessons Learned

### Terraform

Terraform manages the Azure infrastructure.

```text
Terraform
   |
   +-- Resource Group
   +-- ACR
   +-- AKS
   +-- IAM/RBAC
```

### Docker

Docker packages the application.

```text
Node.js source
      |
      v
Docker image
      |
      v
ACR
```

### Kubernetes

Kubernetes runs the application.

```text
Deployment
    |
    v
ReplicaSet
    |
    v
Pod
    |
    v
Container
```

### Service

The Service provides stable networking.

```text
Service :80
     |
     v
Pod :3000
```

### Helm

Helm packages Kubernetes manifests and provides repeatable deployment/versioning.

```text
Helm Chart
    |
    v
Deployment + Service + Config
```

---

# 47. Final Verification Commands

Run these before considering the deployment complete:

```powershell
terraform validate
```

```powershell
terraform plan
```

```powershell
az acr repository show-tags `
  --name acrazureiacdev01 `
  --repository node-app `
  --output table
```

```powershell
kubectl get nodes
```

```powershell
kubectl get pods -n node-app
```

```powershell
kubectl get svc -n node-app
```

```powershell
kubectl get endpointslice -n node-app
```

```powershell
helm list -n node-app
```

```powershell
kubectl describe pod -n node-app <POD_NAME>
```

Port forward:

```powershell
kubectl port-forward -n node-app svc/node-app 3000:80
```

Test:

```powershell
curl.exe http://localhost:3000/health
```

```powershell
curl.exe http://localhost:3000/ready
```

Expected:

```json
{"status":"healthy"}
```

```json
{"status":"ready"}
```

If all of these succeed, the complete Terraform → Azure → ACR → AKS → Helm → Kubernetes → application flow is working.
