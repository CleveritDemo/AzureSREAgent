#!/bin/bash

# Test script for Terraform Azure authentication
# Run this locally to test if your Terraform configuration works

echo "🔧 Testing Terraform Azure Authentication Configuration..."

# Check if Azure CLI is logged in
echo "Checking Azure CLI authentication..."
if az account show > /dev/null 2>&1; then
    echo "✅ Azure CLI is authenticated"
    az account show --query '{subscriptionId:id, tenantId:tenantId, name:name}' -o table
else
    echo "❌ Azure CLI is not authenticated. Please run 'az login'"
    exit 1
fi

# Test Terraform configuration
echo ""
echo "Testing Terraform configuration..."
cd terraform-export-clean

# Initialize Terraform
echo "Initializing Terraform..."
if terraform init -backend=true; then
    echo "✅ Terraform init successful"
else
    echo "❌ Terraform init failed"
    exit 1
fi

# Validate configuration
echo "Validating Terraform configuration..."
if terraform validate; then
    echo "✅ Terraform validation successful"
else
    echo "❌ Terraform validation failed"
    exit 1
fi

# Plan (dry run)
echo "Running Terraform plan (dry run)..."
if terraform plan -out test.tfplan; then
    echo "✅ Terraform plan successful"
    
    # Show plan summary
    echo ""
    echo "Plan summary:"
    if terraform show -json test.tfplan >/dev/null 2>&1; then
        terraform show -json test.tfplan | jq -r '.planned_values.root_module.resources[]? | select(.type | startswith("azurerm_chaos")) | "  - " + .type + "." + .name' 2>/dev/null || echo "  - Could not parse plan JSON, but plan was successful"
    else
        echo "  - Plan was successful but could not extract resource details"
    fi
    
    # Cleanup
    rm -f test.tfplan
else
    echo "❌ Terraform plan failed"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Terraform configuration is ready for GitHub Actions."
echo ""
echo "Next steps:"
echo "1. Ensure these secrets are set in your GitHub repository:"
echo "   - AZURE_CLIENT_ID"
echo "   - AZURE_TENANT_ID"
echo "   - AZURE_SUBSCRIPTION_ID"
echo "2. Run the GitHub Actions workflow to provision chaos experiments"
