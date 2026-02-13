#!/bin/bash
set -e

echo "🔄 Resetting ArgoCD Installation"
echo "================================="
echo ""
echo "This will:"
echo "  1. Tear down existing ArgoCD installation"
echo "  2. Clean up all resources"
echo "  3. Install fresh ArgoCD"
echo "  4. Configure and deploy applications"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Run teardown
echo "▶️  Running teardown..."
bash "$SCRIPT_DIR/teardown-argocd.sh"

echo ""
echo "⏳ Waiting 10 seconds for cleanup to complete..."
sleep 10

# Run setup
echo ""
echo "▶️  Running setup..."
bash "$SCRIPT_DIR/setup-argocd.sh"

echo ""
echo "🎉 Reset complete! ArgoCD is ready to use."
