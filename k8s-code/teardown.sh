#!/bin/bash
set -e

echo "🗑️  Tearing Down House Price Predictor Stack"
echo "==========================================="

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo ""
echo -e "${YELLOW}⚠️  This will delete all deployed resources${NC}"
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Teardown cancelled."
    exit 0
fi

echo ""
echo -e "${RED}Removing Application Components...${NC}"

# Delete application resources
kubectl delete -f manifests/streamlit-deployment.yaml --ignore-not-found=true
kubectl delete -f manifests/streamlit-service.yaml --ignore-not-found=true
kubectl delete -f manifests/model-deployment.yaml --ignore-not-found=true
kubectl delete -f manifests/model-service.yaml --ignore-not-found=true
kubectl delete -f manifests/kube-ops-view-deployment.yaml --ignore-not-found=true
kubectl delete -f manifests/kube-ops-view-service.yaml --ignore-not-found=true

echo ""
echo -e "${RED}Removing Monitoring Stack...${NC}"

# Delete Grafana dashboard
kubectl delete -f manifests/grafana-dashboard-configmap.yaml --ignore-not-found=true

# Uninstall Prometheus Helm release
if helm list -n monitoring | grep -q prom; then
    echo "Uninstalling Prometheus stack..."
    helm uninstall prom -n monitoring
fi

# Delete monitoring namespace
kubectl delete namespace monitoring --ignore-not-found=true

echo ""
echo -e "${RED}✅ Teardown Complete!${NC}"
echo ""
echo "All resources have been removed."
echo ""
echo "To redeploy, run: ./deploy-all.sh"
echo ""
