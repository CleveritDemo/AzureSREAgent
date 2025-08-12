#!/bin/bash

# Chaos Experiment Management Script
# Usage: ./manage-chaos-experiments.sh [list|create|delete|status] [experiment-name]

set -e

RESOURCE_GROUP="eShopCleverRG"
SUBSCRIPTION_ID="5f62fee3-b00a-44d2-86e5-5cf130b28b5d"
TERRAFORM_DIR="./terraform-export-clean"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  list                          List all chaos experiments"
    echo "  status [experiment-name]      Show status of specific experiment"
    echo "  create [template]             Create experiment from template"
    echo "  delete [experiment-name]      Delete experiment (with confirmation)"
    echo "  sync-state                    Synchronize Terraform state"
    echo "  validate                      Validate all Terraform configurations"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 status eshoppodfailure"
    echo "  $0 create pod-failure"
    echo "  $0 delete my-experiment"
    echo "  $0 sync-state"
}

check_prerequisites() {
    echo -e "${BLUE}Checking prerequisites...${NC}"
    
    # Check if Azure CLI is installed and logged in
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI is not installed${NC}"
        exit 1
    fi
    
    # Check if logged in to Azure
    if ! az account show &> /dev/null; then
        echo -e "${RED}Error: Not logged in to Azure. Run 'az login' first${NC}"
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}Error: Terraform is not installed${NC}"
        exit 1
    fi
    
    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All prerequisites met${NC}"
}

list_experiments() {
    echo -e "${BLUE}Listing all chaos experiments...${NC}"
    
    # List from Azure
    echo -e "\n${YELLOW}Azure Chaos Studio Experiments:${NC}"
    az rest --method GET \
        --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Chaos/experiments?api-version=2024-01-01" \
        --query "value[].{Name:name,Location:location,Status:properties.provisioningState}" \
        --output table 2>/dev/null || echo "No experiments found in Azure"
    
    # List from Terraform state
    echo -e "\n${YELLOW}Terraform State Experiments:${NC}"
    if [ -d "$TERRAFORM_DIR" ]; then
        cd "$TERRAFORM_DIR"
        terraform init -backend=true > /dev/null 2>&1
        terraform state list | grep "azurerm_chaos_studio_experiment" | sed 's/azurerm_chaos_studio_experiment\.//' || echo "No experiments found in Terraform state"
        cd - > /dev/null
    else
        echo "Terraform directory not found"
    fi
    
    # List Terraform files
    echo -e "\n${YELLOW}Terraform Configuration Files:${NC}"
    find "$TERRAFORM_DIR" -name "chaos-experiment-*.tf" -exec basename {} \; 2>/dev/null | sed 's/chaos-experiment-//' | sed 's/\.tf$//' || echo "No experiment configuration files found"
}

show_experiment_status() {
    local experiment_name="$1"
    
    if [ -z "$experiment_name" ]; then
        echo -e "${RED}Error: Experiment name required${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Showing status for experiment: $experiment_name${NC}"
    
    # Get experiment details from Azure
    EXPERIMENT_DETAILS=$(az rest --method GET \
        --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Chaos/experiments/$experiment_name?api-version=2024-01-01" \
        2>/dev/null || echo "null")
    
    if [ "$EXPERIMENT_DETAILS" != "null" ]; then
        echo -e "\n${GREEN}✓ Experiment found in Azure${NC}"
        echo "$EXPERIMENT_DETAILS" | jq -r '
            "Name: " + .name,
            "Status: " + .properties.provisioningState,
            "Location: " + .location,
            "Created: " + (.systemData.createdAt // "Unknown"),
            "Last Modified: " + (.systemData.lastModifiedAt // "Unknown")'
        
        # Get experiment executions
        echo -e "\n${YELLOW}Recent Executions:${NC}"
        az rest --method GET \
            --url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Chaos/experiments/$experiment_name/executions?api-version=2024-01-01" \
            --query "value[0:5].{Status:properties.status,Started:properties.startedAt,Stopped:properties.stoppedAt}" \
            --output table 2>/dev/null || echo "No executions found"
    else
        echo -e "${RED}✗ Experiment not found in Azure${NC}"
    fi
    
    # Check Terraform state
    if [ -d "$TERRAFORM_DIR" ]; then
        cd "$TERRAFORM_DIR"
        terraform init -backend=true > /dev/null 2>&1
        if terraform state show "azurerm_chaos_studio_experiment.$experiment_name" > /dev/null 2>&1; then
            echo -e "\n${GREEN}✓ Experiment found in Terraform state${NC}"
            terraform state show "azurerm_chaos_studio_experiment.$experiment_name" | head -20
        else
            echo -e "\n${RED}✗ Experiment not found in Terraform state${NC}"
        fi
        cd - > /dev/null
    fi
    
    # Check for configuration file
    if [ -f "$TERRAFORM_DIR/chaos-experiment-$experiment_name.tf" ]; then
        echo -e "\n${GREEN}✓ Configuration file exists: chaos-experiment-$experiment_name.tf${NC}"
    else
        echo -e "\n${RED}✗ Configuration file not found${NC}"
    fi
}

create_experiment_template() {
    local template_type="$1"
    
    if [ -z "$template_type" ]; then
        echo -e "${RED}Error: Template type required${NC}"
        echo "Available templates: pod-failure, cpu-stress, memory-stress, network-delay"
        exit 1
    fi
    
    echo -e "${BLUE}Creating experiment template: $template_type${NC}"
    
    # Generate a sample experiment name
    EXPERIMENT_NAME="sample-$template_type-$(date +%s)"
    
    echo "Use the GitHub Actions workflow to create the experiment:"
    echo ""
    echo "1. Go to: https://github.com/CleveritDemo/AzureSREAgent/actions/workflows/provision-chaos-experiment.yml"
    echo "2. Click 'Run workflow'"
    echo "3. Fill in the parameters:"
    echo "   - Experiment name: $EXPERIMENT_NAME"
    echo "   - Experiment type: $template_type"
    echo "   - Target namespace: eshop"
    echo "   - Target labels: {\"app\": \"eshop-webmvc\"}"
    echo "   - Duration: 5 minutes"
    echo "   - Action duration: 60s"
    echo "4. Set 'dry_run' to true for testing"
    echo ""
    echo "Or use the GitHub CLI:"
    echo "gh workflow run provision-chaos-experiment.yml \\"
    echo "  --field experiment_name=\"$EXPERIMENT_NAME\" \\"
    echo "  --field experiment_type=\"$template_type\" \\"
    echo "  --field target_namespace=\"eshop\" \\"
    echo "  --field target_labels='{\"app\": \"eshop-webmvc\"}' \\"
    echo "  --field duration_minutes=\"5\" \\"
    echo "  --field action_duration=\"60s\" \\"
    echo "  --field dry_run=true"
}

delete_experiment() {
    local experiment_name="$1"
    
    if [ -z "$experiment_name" ]; then
        echo -e "${RED}Error: Experiment name required${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}⚠️  This will delete the chaos experiment: $experiment_name${NC}"
    echo "This action will:"
    echo "1. Remove the experiment from Azure Chaos Studio"
    echo "2. Remove the resource from Terraform state"
    echo "3. Delete the Terraform configuration file"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " -r
    
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Operation cancelled"
        exit 0
    fi
    
    echo -e "${BLUE}Deleting experiment: $experiment_name${NC}"
    
    # Delete from Terraform
    if [ -d "$TERRAFORM_DIR" ]; then
        cd "$TERRAFORM_DIR"
        terraform init -backend=true > /dev/null 2>&1
        
        # Remove from state
        if terraform state show "azurerm_chaos_studio_experiment.$experiment_name" > /dev/null 2>&1; then
            echo "Removing from Terraform state..."
            terraform destroy -target="azurerm_chaos_studio_experiment.$experiment_name" -auto-approve
        fi
        
        # Remove configuration file
        if [ -f "chaos-experiment-$experiment_name.tf" ]; then
            echo "Removing configuration file..."
            rm -f "chaos-experiment-$experiment_name.tf"
        fi
        
        cd - > /dev/null
    fi
    
    echo -e "${GREEN}✓ Experiment deleted successfully${NC}"
}

sync_terraform_state() {
    echo -e "${BLUE}Synchronizing Terraform state...${NC}"
    
    if [ ! -d "$TERRAFORM_DIR" ]; then
        echo -e "${RED}Error: Terraform directory not found${NC}"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Initialize and refresh state
    echo "Initializing Terraform..."
    terraform init -upgrade
    
    echo "Refreshing state..."
    terraform refresh
    
    echo "Validating configuration..."
    terraform validate
    
    echo "Planning changes..."
    terraform plan -detailed-exitcode
    PLAN_EXIT_CODE=$?
    
    case $PLAN_EXIT_CODE in
        0)
            echo -e "${GREEN}✓ No changes needed - state is in sync${NC}"
            ;;
        1)
            echo -e "${RED}✗ Terraform plan failed${NC}"
            exit 1
            ;;
        2)
            echo -e "${YELLOW}⚠️  Changes detected - run 'terraform apply' to sync${NC}"
            ;;
    esac
    
    cd - > /dev/null
}

validate_configurations() {
    echo -e "${BLUE}Validating all Terraform configurations...${NC}"
    
    if [ ! -d "$TERRAFORM_DIR" ]; then
        echo -e "${RED}Error: Terraform directory not found${NC}"
        exit 1
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Initialize
    terraform init -backend=true > /dev/null 2>&1
    
    # Validate
    if terraform validate; then
        echo -e "${GREEN}✓ All configurations are valid${NC}"
    else
        echo -e "${RED}✗ Configuration validation failed${NC}"
        exit 1
    fi
    
    # Check for syntax errors in individual files
    echo -e "\n${YELLOW}Checking individual experiment files:${NC}"
    for file in chaos-experiment-*.tf; do
        if [ -f "$file" ]; then
            echo -n "Checking $file... "
            if terraform validate -json | jq -e '.valid' > /dev/null 2>&1; then
                echo -e "${GREEN}✓${NC}"
            else
                echo -e "${RED}✗${NC}"
            fi
        fi
    done
    
    cd - > /dev/null
}

# Main script logic
case "${1:-}" in
    "list")
        check_prerequisites
        list_experiments
        ;;
    "status")
        check_prerequisites
        show_experiment_status "$2"
        ;;
    "create")
        create_experiment_template "$2"
        ;;
    "delete")
        check_prerequisites
        delete_experiment "$2"
        ;;
    "sync-state")
        check_prerequisites
        sync_terraform_state
        ;;
    "validate")
        check_prerequisites
        validate_configurations
        ;;
    "help"|"--help"|"-h")
        print_usage
        ;;
    *)
        echo -e "${RED}Error: Unknown command '${1:-}'${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac
