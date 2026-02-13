#!/bin/bash
set -e

echo "🚀 Deploying House Price Predictor Stack to Kubernetes"
echo "========================================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl first."
    exit 1
fi

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ helm not found. Please install helm first."
    exit 1
fi

echo ""
echo -e "${BLUE}📦 Step 1: Deploying Application Components${NC}"
echo "--------------------------------------------"

# Deploy Streamlit
echo "Deploying Streamlit..."
kubectl apply -f manifests/streamlit-deployment.yaml
kubectl apply -f manifests/streamlit-service.yaml

# Deploy Model
echo "Deploying Model API..."
kubectl apply -f manifests/model-deployment.yaml
kubectl apply -f manifests/model-service.yaml

# Deploy Kube Ops View
echo "Deploying Kube Ops View..."
kubectl apply -f manifests/kube-ops-view-deployment.yaml
kubectl apply -f manifests/kube-ops-view-service.yaml

echo ""
echo -e "${BLUE}📊 Step 2: Setting up Monitoring Stack${NC}"
echo "----------------------------------------"

# Create monitoring namespace
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Add Prometheus Helm repo if not exists
if ! helm repo list | grep -q prometheus-community; then
    echo "Adding Prometheus Helm repository..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
fi

# Update Helm repos
echo "Updating Helm repositories..."
helm repo update

# Install Prometheus Stack
echo "Installing Prometheus Stack..."
helm upgrade --install prom -n monitoring prometheus-community/kube-prometheus-stack -f prometheus-values.yaml

# Wait for Prometheus stack to be ready
echo "Waiting for Prometheus stack to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=180s
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n monitoring --timeout=180s

# Apply Grafana dashboard
echo "Applying custom Grafana dashboard..."
kubectl apply -f manifests/grafana-dashboard-configmap.yaml

echo ""
echo -e "${BLUE}⏳ Step 3: Waiting for Deployments${NC}"
echo "-----------------------------------"

# Wait for application deployments
kubectl wait --for=condition=available deployment/streamlit --timeout=120s
kubectl wait --for=condition=available deployment/model --timeout=120s
kubectl wait --for=condition=available deployment/kube-ops-view --timeout=120s

echo ""
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo "======================="
echo ""
echo -e "${YELLOW}📍 Access Points:${NC}"
echo ""
echo "Streamlit App:"
echo "  http://localhost:30000"
echo ""
echo "Model API:"
echo "  http://localhost:30100"
echo ""
echo "Kube Ops View:"
echo "  http://localhost:32000"
echo ""
echo "Grafana:"
echo "  URL: http://localhost:30200"
echo "  Username: admin"
echo "  Password: TWhi6gjUhB9d6eP7FrTnxs0At9ek2rhnqyFS7NLe"
echo ""
echo "Prometheus:"
echo "  kubectl port-forward -n monitoring svc/prom-kube-prometheus-stack-prometheus 9090:9090"
echo "  Then visit: http://localhost:9090"
echo ""
echo -e "${YELLOW}📊 View Resources:${NC}"
echo "  kubectl get all -n default"
echo "  kubectl get all -n monitoring"
echo ""
