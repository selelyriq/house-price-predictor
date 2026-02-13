# Kubernetes Deployment Guide

This directory contains all Kubernetes manifests and deployment scripts for the House Price Predictor application.

## 📁 Directory Structure

```
k8s-code/
├── manifests/
│   ├── streamlit-deployment.yaml          # Streamlit app deployment
│   ├── streamlit-service.yaml             # Streamlit NodePort service (port 30000)
│   ├── model-deployment.yaml              # Model API deployment
│   ├── model-service.yaml                 # Model NodePort service (port 30100)
│   ├── kube-ops-view-deployment.yaml      # Kube Ops View deployment
│   ├── kube-ops-view-service.yaml         # Kube Ops View service (port 32000)
│   └── grafana-dashboard-configmap.yaml   # Custom Grafana dashboard
├── prometheus-values.yaml                 # Helm values for Prometheus stack
├── deploy-all.sh                          # Full deployment script
├── teardown.sh                            # Cleanup script
└── README.md                              # This file
```

## 🚀 Quick Start

### Deploy Everything

```bash
cd k8s-code
./deploy-all.sh
```

This script will:
1. Deploy Streamlit app and service
2. Deploy Model API and service
3. Deploy Kube Ops View
4. Install Prometheus + Grafana monitoring stack
5. Apply custom Grafana dashboard

### Teardown Everything

```bash
cd k8s-code
./teardown.sh
```

This will remove all deployed resources and namespaces.

## 📦 Manual Deployment

If you prefer to deploy components individually:

### 1. Deploy Application Components

```bash
# Streamlit
kubectl apply -f manifests/streamlit-deployment.yaml
kubectl apply -f manifests/streamlit-service.yaml

# Model API
kubectl apply -f manifests/model-deployment.yaml
kubectl apply -f manifests/model-service.yaml

# Kube Ops View (optional)
kubectl apply -f manifests/kube-ops-view-deployment.yaml
kubectl apply -f manifests/kube-ops-view-service.yaml
```

### 2. Deploy Monitoring Stack

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Add Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install Prometheus stack
helm upgrade --install prom -n monitoring \
  prometheus-community/kube-prometheus-stack \
  -f prometheus-values.yaml

# Apply custom Grafana dashboard
kubectl apply -f manifests/grafana-dashboard-configmap.yaml
```

## 🌐 Access Points

After deployment, access your services:

| Service | URL | Notes |
|---------|-----|-------|
| Streamlit App | http://localhost:30000 | Main application UI |
| Model API | http://localhost:30100 | Prediction API endpoint |
| Kube Ops View | http://localhost:32000 | Cluster visualization |
| Grafana | http://localhost:30200 | Metrics & dashboards |
| Prometheus | kubectl port-forward... | Metrics database |

### Grafana Credentials

- **Username**: `admin`
- **Password**: `TWhi6gjUhB9d6eP7FrTnxs0At9ek2rhnqyFS7NLe`

### Prometheus Access

```bash
kubectl port-forward -n monitoring svc/prom-kube-prometheus-stack-prometheus 9090:9090
# Then visit: http://localhost:9090
```

## 🔧 Configuration Details

### Streamlit Deployment

- **Image**: `lyriqsele/house-price-predictor-streamlit:latest`
- **Port**: 8501 (internal), 30000 (NodePort)
- **Environment**: `API_URL=http://model:8000` (uses Kubernetes DNS)

### Model Deployment

- **Image**: `lyriqsele/house-price-predictor-api:latest`
- **Port**: 8000 (internal), 30100 (NodePort)

### Monitoring Stack

- **Grafana**: NodePort 30200
- **Prometheus**: ClusterIP (use port-forward)
- **Alertmanager**: Enabled
- **Retention**: 10 days

## 📊 Grafana Dashboard

A custom dashboard is automatically provisioned with:
- CPU usage metrics
- Memory consumption
- Network I/O
- Pod health status

Find it in Grafana: **"House Price Predictor - Application Monitoring"**

## 🔄 Updating Deployments

### Update Application Images

```bash
# Update the image tag in deployment YAML
kubectl set image deployment/streamlit \
  house-price-predictor-streamlit=lyriqsele/house-price-predictor-streamlit:v2

# Or apply updated manifest
kubectl apply -f manifests/streamlit-deployment.yaml
```

### Update Prometheus Values

```bash
# Edit prometheus-values.yaml, then:
helm upgrade prom -n monitoring \
  prometheus-community/kube-prometheus-stack \
  -f prometheus-values.yaml
```

## 🔍 Troubleshooting

### Check Pod Status

```bash
# Application pods
kubectl get pods -n default

# Monitoring pods
kubectl get pods -n monitoring
```

### View Logs

```bash
# Streamlit logs
kubectl logs -f deployment/streamlit

# Model logs
kubectl logs -f deployment/model

# Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana
```

### Check Services

```bash
# List all services
kubectl get svc -n default
kubectl get svc -n monitoring
```

### DNS Resolution Test

```bash
# Test from Streamlit pod
kubectl exec deployment/streamlit -- getent hosts model

# Should return: 10.96.49.22 model.default.svc.cluster.local
```

## 📝 Prerequisites

- Kubernetes cluster (kind, minikube, or cloud provider)
- kubectl configured and connected
- Helm 3.x installed
- Container images available in registry

## 🏗️ Architecture

```
┌─────────────────┐
│   Streamlit     │
│   (Port 30000)  │
└────────┬────────┘
         │ HTTP
         │ http://model:8000
         ▼
┌─────────────────┐
│   Model API     │
│   (Port 30100)  │
└─────────────────┘
         │
         │ Metrics
         ▼
┌─────────────────┐
│   Prometheus    │
│   + Grafana     │
│   (Port 30200)  │
└─────────────────┘
```

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [Grafana Documentation](https://grafana.com/docs/)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
