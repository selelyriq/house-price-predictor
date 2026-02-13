#!/bin/bash
set -e

echo "🗑️  Tearing down ArgoCD"
echo "======================"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="stable"

echo ""
echo -e "${YELLOW}⚠️  This will remove ArgoCD and all managed applications${NC}"
echo ""

# Delete ArgoCD application first (this will clean up managed resources)
echo "Deleting ArgoCD applications..."
kubectl delete applications --all -n $ARGOCD_NAMESPACE 2>/dev/null || echo "No applications found"

# Wait a moment for cleanup
sleep 5

# Delete ArgoCD
echo "Uninstalling ArgoCD..."
kubectl delete -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml 2>/dev/null || echo "ArgoCD not found"

# Delete namespace
echo "Deleting ArgoCD namespace..."
kubectl delete namespace $ARGOCD_NAMESPACE --timeout=60s 2>/dev/null || echo "Namespace already deleted"

# Clean up any remaining resources in default namespace
echo "Cleaning up application resources..."
kubectl delete deployment,service,configmap -l app.kubernetes.io/managed-by=argocd -n default 2>/dev/null || echo "No managed resources found"

echo ""
echo -e "${RED}✅ ArgoCD teardown complete!${NC}"
echo ""
