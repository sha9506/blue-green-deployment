# Jenkins Setup Guide for Blue-Green Deployment

## 📋 Prerequisites

Before setting up Jenkins, ensure you have:

### Required Software
- ✅ Jenkins installed (version 2.300+)
- ✅ Docker installed on Jenkins server
- ✅ kubectl installed and configured
- ✅ Access to Kubernetes cluster (Minikube, EKS, GKE, AKS, etc.)
- ✅ Docker Hub account (or private registry)
- ✅ Git installed

### Jenkins Plugins Required
Install these plugins from **Manage Jenkins → Manage Plugins**:

1. **Docker Pipeline** - For Docker operations
2. **Kubernetes CLI** - For kubectl commands
3. **Git Plugin** - For repository checkout
4. **Pipeline** - For pipeline jobs
5. **Credentials Binding** - For secure credentials
6. **Blue Ocean** (Optional) - For better UI

---

## 🔐 Step 1: Configure Jenkins Credentials

### A. Docker Hub Credentials

1. Navigate to: **Jenkins Dashboard → Manage Jenkins → Manage Credentials**
2. Click on **(global)** domain
3. Click **Add Credentials**
4. Select **Username with password**
5. Fill in:
   ```
   Username: sha9506 (your Docker Hub username)
   Password: <your Docker Hub password or access token>
   ID: docker-hub-credentials
   Description: Docker Hub Credentials
   ```
6. Click **Create**

**💡 Tip:** Use Docker Hub Access Token instead of password:
- Go to Docker Hub → Account Settings → Security → New Access Token
- Copy the token and use it as the password

### B. Kubernetes Config (Optional - if not already configured)

If Jenkins doesn't have kubectl access:

1. Click **Add Credentials**
2. Select **Secret file**
3. Choose your kubeconfig file (usually at `~/.kube/config`)
4. Fill in:
   ```
   ID: kubeconfig
   Description: Kubernetes Config
   ```
5. Click **Create**

---

## 🏗️ Step 2: Create Jenkins Pipeline Job

### Option A: Multibranch Pipeline (Recommended for GitHub)

1. **Create New Job:**
   - Click **New Item**
   - Enter job name: `blue-green-deployment`
   - Select **Multibranch Pipeline**
   - Click **OK**

2. **Configure Branch Sources:**
   - Click **Add source** → **Git**
   - **Project Repository**: `https://github.com/sha9506/blue-green-deployment.git`
   - If private repo, add credentials (click **Add** → Jenkins)
   - **Behaviors**: Leave default or customize

3. **Build Configuration:**
   - **Mode**: by Jenkinsfile
   - **Script Path**: `Jenkinsfile` (default)

4. **Scan Repository Triggers:**
   - ☑️ Periodically if not otherwise run
   - **Interval**: 1 day (or as needed)

5. Click **Save**

### Option B: Standard Pipeline Job

1. **Create New Job:**
   - Click **New Item**
   - Enter job name: `blue-green-deployment`
   - Select **Pipeline**
   - Click **OK**

2. **General Section:**
   - ☑️ GitHub project (optional)
   - **Project url**: `https://github.com/sha9506/blue-green-deployment/`

3. **Build Triggers:**
   - ☑️ Poll SCM (if you want automatic builds)
   - **Schedule**: `H/5 * * * *` (checks every 5 minutes)
   - Or use GitHub webhooks for instant triggers

4. **Pipeline Section:**
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: `https://github.com/sha9506/blue-green-deployment.git`
   - **Branch Specifier**: `*/main` (or your branch)
   - **Script Path**: `Jenkinsfile`

5. Click **Save**

---

## 🚀 Step 3: Verify Jenkins Agent Setup

### Ensure Docker is Accessible

Your Jenkins agent needs Docker access. Test with:

1. Go to **Manage Jenkins → Script Console**
2. Run this script:
   ```groovy
   def process = "docker --version".execute()
   process.waitFor()
   println process.text
   ```

If Docker is not found, you need to:
- Install Docker on Jenkins server
- Add Jenkins user to docker group: `sudo usermod -aG docker jenkins`
- Restart Jenkins: `sudo systemctl restart jenkins`

### Ensure kubectl is Accessible

Test kubectl access:

1. In **Script Console**, run:
   ```groovy
   def process = "kubectl version --client".execute()
   process.waitFor()
   println process.text
   ```

If kubectl is not found:
- Install kubectl: https://kubernetes.io/docs/tasks/tools/
- Configure kubeconfig file
- Ensure Jenkins has access to the config

---

## 🎯 Step 4: Run Your First Build

### Initial Setup

1. **Navigate to your pipeline job**
2. Click **Build Now** (or **Scan Multibranch Pipeline Now**)
3. Jenkins will:
   - Checkout code from GitHub
   - Determine current deployment color
   - Build Docker image
   - Push to Docker Hub
   - Deploy to Kubernetes
   - Switch traffic

### Monitor the Build

1. Click on the build number (e.g., **#1**)
2. Click **Console Output** to see logs
3. Watch the pipeline stages execute

### Expected Pipeline Flow

```
Stage 1: Checkout ✓
  └─ Clones repository from GitHub

Stage 2: Build Docker Image ✓
  └─ Determines next color (blue/green)
  └─ Builds Docker image
  └─ Tags as flask-blue:latest or flask-green:latest

Stage 3: Push to Docker Hub ✓
  └─ Authenticates to Docker Hub
  └─ Pushes image to sha9506/flask-{color}:latest

Stage 4: Deploy to Kubernetes ✓
  └─ Applies deployment-{color}.yaml
  └─ Updates service selector to route traffic
```

---

## 🐛 Troubleshooting Common Issues

### Issue 1: Docker Login Failed

**Error**: `Error: Cannot perform an interactive login from a non TTY device`

**Solution**:
- Verify credentials ID matches: `docker-hub-credentials`
- Ensure credentials are in (global) domain
- Try recreating credentials
- Test Docker Hub login manually

### Issue 2: kubectl Command Not Found

**Error**: `kubectl: command not found`

**Solution**:
```bash
# Install kubectl on Jenkins server
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

### Issue 3: Kubernetes Context Not Set

**Error**: `The connection to the server localhost:8080 was refused`

**Solution**:
```bash
# Configure kubectl for your cluster
# For Minikube:
kubectl config use-context minikube

# For cloud providers, get credentials:
# AWS EKS:
aws eks update-kubeconfig --name your-cluster-name --region us-east-1

# Google GKE:
gcloud container clusters get-credentials your-cluster-name --region us-central1

# Azure AKS:
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

### Issue 4: Permission Denied (Docker)

**Error**: `Got permission denied while trying to connect to the Docker daemon socket`

**Solution**:
```bash
# Add Jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins

# Verify
sudo -u jenkins docker ps
```

### Issue 5: Image Pull Errors in Kubernetes

**Error**: `Failed to pull image "sha9506/flask-blue:latest": rpc error`

**Solution**:
```bash
# Verify image exists in Docker Hub
docker pull sha9506/flask-blue:latest

# Check if image pull policy is correct
# In deployment files, ensure: imagePullPolicy: Always

# For private registries, create image pull secret:
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=sha9506 \
  --docker-password=<your-password> \
  --docker-email=<your-email>

# Then add to deployment:
spec:
  imagePullSecrets:
  - name: regcred
```

### Issue 6: Service Not Switching Traffic

**Error**: Traffic still goes to old deployment after switch

**Solution**:
```bash
# Verify service selector
kubectl get service flask-service -o yaml

# Check pod labels match service selector
kubectl get pods --show-labels

# Manually patch service if needed
kubectl patch service flask-service -p '{"spec":{"selector":{"version":"green"}}}'

# Verify endpoints
kubectl get endpoints flask-service
```

---

## 🔄 Step 5: Testing the Deployment

### Verify Deployment

```bash
# Check deployments
kubectl get deployments

# Expected output:
# NAME          READY   UP-TO-DATE   AVAILABLE   AGE
# flask-blue    1/1     1            1           5m
# flask-green   1/1     1            1           2m

# Check service
kubectl get service flask-service

# Check which version is active
kubectl get service flask-service -o jsonpath='{.spec.selector.version}'
```

### Test Application

```bash
# Get service external IP (for LoadBalancer)
kubectl get service flask-service

# Access application
curl http://<EXTERNAL-IP>

# Or use port-forward for local testing
kubectl port-forward service/flask-service 8080:80

# Test in browser or curl
curl http://localhost:8080
```

### Manual Traffic Switch

```bash
# Switch to blue
kubectl patch service flask-service -p '{"spec":{"selector":{"version":"blue"}}}'

# Switch to green  
kubectl patch service flask-service -p '{"spec":{"selector":{"version":"green"}}}'

# Verify current version
curl http://<SERVICE-IP>
```

---

## 🔧 Advanced Configuration

### Add Webhook for Auto-Build

1. **In GitHub:**
   - Go to repository → Settings → Webhooks
   - Click **Add webhook**
   - **Payload URL**: `http://<JENKINS-URL>/github-webhook/`
   - **Content type**: application/json
   - **Events**: Just the push event
   - Click **Add webhook**

2. **In Jenkins:**
   - Job → Configure
   - Build Triggers → ☑️ GitHub hook trigger for GITScm polling

### Add Build Parameters

Modify Jenkinsfile to accept parameters:

```groovy
pipeline {
    agent any
    
    parameters {
        choice(
            name: 'TARGET_COLOR',
            choices: ['auto', 'blue', 'green'],
            description: 'Deployment color (auto determines automatically)'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test stage'
        )
    }
    
    // ... rest of pipeline
}
```

### Add Health Checks

Update app.py to include health endpoint:

```python
@app.route('/health')
def health():
    return {"status": "healthy", "version": os.getenv("APP_VERSION", "unknown")}, 200
```

Then add health check stage to Jenkinsfile:

```groovy
stage('Health Check') {
    steps {
        script {
            sleep 10  // Wait for deployment to stabilize
            sh """
                kubectl wait --for=condition=ready pod \
                  -l app=flask,version=${env.NEXT_COLOR} \
                  --timeout=60s
            """
            echo "Health check passed for ${env.NEXT_COLOR}"
        }
    }
}
```

---

## 📊 Monitoring Your Pipeline

### Jenkins Dashboard

- **Blue Ocean**: Better visualization of pipeline stages
- **Build History**: Track success/failure trends
- **Console Output**: Detailed logs for debugging

### Kubernetes Monitoring

```bash
# Watch pod status
kubectl get pods -w

# Check logs
kubectl logs -f deployment/flask-blue
kubectl logs -f deployment/flask-green

# Describe resources
kubectl describe deployment flask-blue
kubectl describe service flask-service
```

### Key Metrics to Monitor

- ✅ Build success rate
- ⏱️ Build duration
- 🚀 Deployment frequency
- 🔄 Rollback frequency
- ⚡ Time to switch traffic

---

## 📚 Next Steps

1. **Add Automated Tests**: Integrate unit/integration tests before deployment
2. **Implement Rollback**: Add automatic rollback on health check failure
3. **Add Notifications**: Slack/Email notifications on build status
4. **Security Scanning**: Add container security scanning stage
5. **Resource Monitoring**: Set up Prometheus/Grafana for metrics
6. **Cost Optimization**: Scale down inactive environment

---

## 🆘 Need Help?

- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Docker Documentation**: https://docs.docker.com/

## ✅ Checklist

Before running your first build, ensure:

- [ ] Jenkins is running and accessible
- [ ] Required plugins are installed
- [ ] Docker Hub credentials are configured
- [ ] kubectl has access to Kubernetes cluster
- [ ] Docker is installed on Jenkins server
- [ ] GitHub repository is accessible
- [ ] Pipeline job is created
- [ ] Kubernetes deployments are ready

---

**Good luck with your blue-green deployment! 🚀**
