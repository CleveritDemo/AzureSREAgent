output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.eshop_rg.name
}

output "container_registry_login_server" {
  description = "Login server URL for the container registry"
  value       = azurerm_container_registry.eshop_acr.login_server
}

output "sql_server_fqdn" {
  description = "Fully qualified domain name of the SQL Server"
  value       = azurerm_mssql_server.eshop_sql_server.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "Name of the SQL database"
  value       = azurerm_mssql_database.eshop_db.name
}

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.eshop_aks.name
}

output "aks_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.eshop_aks.fqdn
}

output "aks_kube_config" {
  description = "Raw kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.eshop_aks.kube_config_raw
  sensitive   = true
}
