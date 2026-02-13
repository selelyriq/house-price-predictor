#!/bin/bash
set -e

echo "🚀 Setting up ArgoCD for House Price Predictor"
echo "=============================================="

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ARGOCD_NAMESPACE="argocd"
ARGOCD_VERSION="stable"
ADMIN_PASSWORD="password"
APP_NAME="house-price-predictor"
REPO_URL="https://github.com/selelyriq/house-price-predictor.git"
REPO_PATH="k8s-code/manifests"
TARGET_NAMESPACE="default"

echo ""
echo -e "${BLUE}📦 Step 1: Installing ArgoCD${NC}"
echo "-------------------------------"

# Create namespace
kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Install ArgoCD
echo "Installing ArgoCD $ARGOCD_VERSION..."
kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml

# Wait for ArgoCD to be ready
echo "Waiting for ArgoCD pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n $ARGOCD_NAMESPACE --timeout=300s

echo ""
echo -e "${BLUE}🔐 Step 2: Configuring Admin Password${NC}"
echo "----------------------------------------"

# Generate bcrypt hash for the password
BCRYPT_HASH=$(htpasswd -nbBC 10 admin $ADMIN_PASSWORD | cut -d: -f2)

# Update the admin password
kubectl -n $ARGOCD_NAMESPACE patch secret argocd-secret \
  -p "{\"stringData\": {
    \"admin.password\": \"$BCRYPT_HASH\",
    \"admin.passwordMtime\": \"$(date +%FT%T%Z)\"
  }}"

# Restart ArgoCD server to pick up new password
kubectl -n $ARGOCD_NAMESPACE rollout restart deployment/argocd-server
kubectl -n $ARGOCD_NAMESPACE rollout status deployment/argocd-server --timeout=120s

echo ""
echo -e "${BLUE}🔗 Step 3: Adding Cluster Configuration${NC}"
echo "------------------------------------------"

# Add in-cluster configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: cluster-in-cluster
  namespace: $ARGOCD_NAMESPACE
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: in-cluster
  server: https://kubernetes.default.svc
  config: |
    {
      "tlsClientConfig": {
        "insecure": false
      }
    }
EOF

echo ""
echo -e "${BLUE}🚀 Step 4: Creating ArgoCD Application${NC}"
echo "----------------------------------------"

# Create ArgoCD application
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: $APP_NAME
  namespace: $ARGOCD_NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  source:
    repoURL: $REPO_URL
    targetRevision: main
    path: $REPO_PATH
  destination:
    server: https://kubernetes.default.svc
    namespace: $TARGET_NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - CreateNamespace=true
      - PruneLast=true
      - RespectIgnoreDifferences=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  project: default
  revisionHistoryLimit: 10
EOF

# Wait for application to sync
echo "Waiting for application to sync..."
sleep 5
kubectl wait --for=condition=ready pod -l app=streamlit -n $TARGET_NAMESPACE --timeout=180s 2>/dev/null || echo "Application is syncing..."

echo ""
echo -e "${GREEN}✅ ArgoCD Setup Complete!${NC}"
echo "=========================="
echo ""
echo -e "${YELLOW}📍 Access Points:${NC}"
echo ""
echo "ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443"
echo "  Then visit: https://localhost:8080"
echo "  Username: admin"
echo "  Password: $ADMIN_PASSWORD"
echo ""
echo "Application Status:"
echo "  kubectl -n $ARGOCD_NAMESPACE get application $APP_NAME"
echo ""
echo "Deployed Services (after sync completes):"
echo "  Streamlit: http://localhost:30000"
echo "  Model API: http://localhost:30100"
echo "  Kube Ops View: http://localhost:32000"
echo ""
echo -e "${YELLOW}💡 Tips:${NC}"
echo "  - ArgoCD will auto-sync changes from your Git repository"
echo "  - To manually sync: kubectl -n $ARGOCD_NAMESPACE patch application $APP_NAME --type merge -p '{\"spec\":{\"syncPolicy\":null}}'"
echo "  - To uninstall: kubectl delete -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/$ARGOCD_VERSION/manifests/install.yaml"
echo ""
