# Blue-Green Deployment Demo

A comprehensive demonstration of blue-green deployment strategy using Jenkins, Docker, and Kubernetes. This project showcases zero-downtime deployments with automated CI/CD pipelines.

## 🏗️ Architecture

This project implements a blue-green deployment pattern with the following components:

- **Flask Application**: A simple Python web service with health checks and API endpoints
- **Docker**: Containerization for consistent deployments
- **Kubernetes**: Orchestration with separate blue and green deployments
- **Jenkins**: CI/CD pipeline automation
- **Load Balancer**: Traffic switching between environments

## 📁 Project Structure

```
blue-green-deployment/
│
├── Jenkinsfile                 # Jenkins pipeline configuration
├── Dockerfile                  # Container build instructions
├── app/
│   ├── app.py                 # Flask web application
│   └── requirements.txt       # Python dependencies
├── k8s/
│   ├── deployment-blue.yaml   # Blue environment deployment
│   ├── deployment-green.yaml  # Green environment deployment
│   └── service.yaml          # Load balancer and services
└── README.md                 # Project documentation
```

## 🚀 Quick Start

### Prerequisites

- Docker installed locally
- Kubernetes cluster (minikube, EKS, GKE, etc.)
- Jenkins with required plugins:
  - Docker Pipeline
  - Kubernetes CLI
  - Pipeline Stage View
- kubectl configured for your cluster

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/blue-green-deployment.git
   cd blue-green-deployment
   ```

2. **Build and run locally**
   ```bash
   # Build Docker image
   docker build -t blue-green-app:local .
   
   # Run container
   docker run -p 5000:5000 blue-green-app:local
   ```

3. **Test the application**
   ```bash
   curl http://localhost:5000
   curl http://localhost:5000/health
   curl http://localhost:5000/info
   ```

### Kubernetes Deployment

1. **Deploy to Kubernetes**
   ```bash
   # Apply all manifests
   kubectl apply -f k8s/
   
   # Check deployment status
   kubectl get deployments
   kubectl get services
   kubectl get pods
   ```

2. **Access the application**
   ```bash
   # Get external IP (for LoadBalancer)
   kubectl get service blue-green-service
   
   # Or use port-forward for testing
   kubectl port-forward service/blue-green-service 8080:80
   curl http://localhost:8080
   ```

## 🔄 Blue-Green Deployment Process

### How It Works

1. **Blue Environment**: Currently serving production traffic
2. **Green Environment**: New version deployed alongside blue
3. **Health Checks**: Automated testing of green environment
4. **Traffic Switch**: Instant cutover from blue to green
5. **Rollback**: Quick switch back to blue if issues arise

### Jenkins Pipeline Stages

1. **Checkout**: Pull latest code from repository
2. **Build**: Create Docker image and push to registry
3. **Deploy Blue**: Update blue environment with new image
4. **Health Check Blue**: Verify blue deployment health
5. **Switch to Blue**: Route traffic to blue environment
6. **Deploy Green**: Update green environment with new image
7. **Health Check Green**: Verify green deployment health
8. **Switch to Green**: Route production traffic to green
9. **Cleanup**: Scale down old blue environment

### Manual Deployment Commands

```bash
# Deploy new version to blue environment
kubectl set image deployment/blue-deployment app=your-registry.com/blue-green-app:v2.0.0

# Wait for rollout to complete
kubectl rollout status deployment/blue-deployment

# Switch traffic to blue
kubectl patch service blue-green-service -p '{"spec":{"selector":{"version":"blue"}}}'

# Deploy to green environment
kubectl set image deployment/green-deployment app=your-registry.com/blue-green-app:v2.0.0
kubectl rollout status deployment/green-deployment

# Switch traffic to green
kubectl patch service blue-green-service -p '{"spec":{"selector":{"version":"green"}}}'
```

## 🔧 Configuration

### Environment Variables

The application supports the following environment variables:

- `APP_NAME`: Application name (default: "Blue-Green Demo App")
- `APP_VERSION`: Version number (default: "1.0.0")
- `ENVIRONMENT`: Environment identifier ("blue" or "green")
- `FLASK_DEBUG`: Enable debug mode ("true"/"false")
- `PORT`: Application port (default: 5000)
- `HOST`: Bind address (default: "0.0.0.0")

### Jenkins Configuration

Update the following variables in the Jenkinsfile:

- `DOCKER_REGISTRY`: Your Docker registry URL
- `IMAGE_NAME`: Docker image name
- `KUBECONFIG_CREDENTIALS`: Jenkins credential ID for kubeconfig

### Kubernetes Resources

Adjust resource limits in deployment files:

```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
```

## 📊 Monitoring and Health Checks

### Health Endpoints

- `/health`: Basic health check (returns 200 if healthy)
- `/info`: Detailed application and system information
- `/`: Welcome page with current environment info

### Kubernetes Probes

- **Liveness Probe**: Detects if container needs restart
- **Readiness Probe**: Determines if pod can receive traffic

## 🔒 Security Considerations

- Non-root user in Docker container
- Resource limits to prevent resource exhaustion
- Image pull secrets for private registries
- Network policies (implement as needed)

## 🐛 Troubleshooting

### Common Issues

1. **Image Pull Errors**
   ```bash
   # Check image pull secrets
   kubectl get secrets
   kubectl describe pod <pod-name>
   ```

2. **Service Not Accessible**
   ```bash
   # Check service endpoints
   kubectl get endpoints
   kubectl describe service blue-green-service
   ```

3. **Deployment Failures**
   ```bash
   # Check deployment status
   kubectl describe deployment blue-deployment
   kubectl logs -l app=blue-green-app,version=blue
   ```

### Rollback Procedures

```bash
# Rollback deployment
kubectl rollout undo deployment/green-deployment

# Switch traffic back to blue
kubectl patch service blue-green-service -p '{"spec":{"selector":{"version":"blue"}}}'

# Check rollback status
kubectl rollout status deployment/green-deployment
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Resources

- [Blue-Green Deployment Pattern](https://docs.aws.amazon.com/whitepapers/latest/blue-green-deployments/welcome.html)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 📞 Support

For questions or support, please:
1. Check the troubleshooting section above
2. Search existing GitHub issues
3. Create a new issue with detailed information