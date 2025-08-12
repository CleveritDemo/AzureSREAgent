# Infrastructure Migration Summary
Generated: 2025-08-12 12:26:58

## Current Environment
- Tenant ID: 1033d128-85ad-47b4-8c85-0a28b6ce0297
- Subscription ID: 5f62fee3-b00a-44d2-86e5-5cf130b28b5d
- Subscription Name: Patrocinio de Microsoft Azure
- Resource Group: eShopCleverRG
- Location: eastus2

## Resources Found
- Total Resources: 10
- AKS Cluster: eshopcleveraks
- Container Registry: eshopcleveracr
- SQL Server: eshopclever-sqlsrv
- SQL Database: eshopdb

## Migration Requirements
1. New tenant and subscription with same resource quotas
2. Service Principal with Contributor and Chaos Studio permissions
3. Same resource names available in new environment
4. Network connectivity for data transfer

## Files Exported
- current-environment.json - Current authentication details
- resource-group.json - Resource group configuration
- all-resources.json - All resources in the resource group
- aks-cluster.json - AKS cluster detailed configuration
- container-registry.json - ACR configuration
- acr-repositories.json - List of container repositories
- sql-server.json - SQL Server configuration
- sql-database.json - SQL Database configuration
- terraform.tfstate - Current Terraform state
- terraform-resources.txt - List of Terraform-managed resources
- *.tf - Terraform configuration files
- k8s-*.yaml - Kubernetes resource configurations

## Next Steps
1. Review exported configurations
2. Prepare new environment (tenant/subscription)
3. Create Service Principal with required permissions
4. Update Terraform configuration for new environment
5. Execute migration using migration scripts
6. Validate migrated infrastructure
7. Update DNS and external configurations
8. Test all applications and workflows

## Important Notes
- Keep this export as backup during migration
- Verify all resource names are available in new environment
- Some globally unique names (ACR, SQL Server) may need temporary alternatives
- Plan for minimal downtime during DNS switchover
