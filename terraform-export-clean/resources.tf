# Resource Group
resource "azurerm_resource_group" "eshop_rg" {
  name     = var.resource_group_name
  location = var.resource_group_location

  tags = {
    environment = var.environment
    project     = "eshop"
  }
}

# Container Registry
resource "azurerm_container_registry" "eshop_acr" {
  name                = "${var.project_name}acr${substr(random_string.domain_verification.result, 0, 4)}"
  resource_group_name = azurerm_resource_group.eshop_rg.name
  location            = "East US"  # Note: Different from RG location
  sku                 = "Basic"
  admin_enabled       = true

  public_network_access_enabled = true
  anonymous_pull_enabled         = false
  data_endpoint_enabled          = false
  network_rule_bypass_option     = "AzureServices"

  tags = {
    environment = var.environment
    project     = "eshop"
  }
}

# SQL Server
resource "azurerm_mssql_server" "eshop_sql_server" {
  name                         = "${var.project_name}-sqlsrv-${substr(random_string.domain_verification.result, 0, 4)}"
  resource_group_name          = azurerm_resource_group.eshop_rg.name
  location                     = azurerm_resource_group.eshop_rg.location
  version                      = "12.0"
  administrator_login          = "eshopsreadmin"
  administrator_login_password = var.sql_admin_password  # Use variable for security
  minimum_tls_version          = "1.2"
  public_network_access_enabled = true

  tags = {
    environment = var.environment
    project     = "eshop"
  }
}

# SQL Database - eshopdb
resource "azurerm_mssql_database" "eshop_db" {
  name         = "eshopdb"
  server_id    = azurerm_mssql_server.eshop_sql_server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  sku_name     = "S0"  # Standard tier
  max_size_gb  = 250
  
  tags = {
    environment = var.environment
    project     = "eshop"
  }
}

# SQL Firewall Rule - Allow all (for demo purposes)
resource "azurerm_mssql_firewall_rule" "allow_all" {
  name             = "AllowAll"
  server_id        = azurerm_mssql_server.eshop_sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "255.255.255.255"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "eshop_aks" {
  name                = "${var.project_name}aks"
  location            = "East US"  # Note: Different from RG location
  resource_group_name = azurerm_resource_group.eshop_rg.name
  dns_prefix          = "${var.project_name}ak-${var.resource_group_name}-${substr(var.subscription_id, 0, 6)}"
  kubernetes_version  = "1.32"

  default_node_pool {
    name                = "nodepool1"
    min_count          = 1                  # Minimum nodes for autoscaling
    max_count          = 2                  # Maximum nodes (as requested)
    vm_size            = "Standard_D2s_v3"  # Changed to available VM size
    type               = "VirtualMachineScaleSets"
    os_disk_size_gb    = 128
    os_disk_type       = "Managed"
    max_pods           = 250

    upgrade_settings {
      max_surge = "10%"
    }
  }

  # Enable cluster autoscaler with autorecovery settings
  auto_scaler_profile {
    balance_similar_node_groups      = false
    expander                        = "random"
    max_graceful_termination_sec    = "300"
    max_node_provisioning_time      = "7m"
    max_unready_nodes              = 3
    max_unready_percentage         = 45
    new_pod_scale_up_delay         = "10s"
    scale_down_delay_after_add     = "10m"
    scale_down_delay_after_delete  = "10s"
    scale_down_delay_after_failure = "3m"
    scan_interval                  = "10s"
    scale_down_unneeded           = "10m"
    scale_down_unready            = "20m"
    scale_down_utilization_threshold = 0.5
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = "azureuser"

    ssh_key {
      key_data = var.ssh_public_key  # Use variable for SSH key
    }
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    dns_service_ip      = "10.0.0.10"
    service_cidr        = "10.0.0.0/16"
    pod_cidr            = "10.244.0.0/16"
    load_balancer_sku   = "standard"
    outbound_type       = "loadBalancer"
  }

  storage_profile {
    blob_driver_enabled         = false
    disk_driver_enabled         = true
    file_driver_enabled         = true
    snapshot_controller_enabled = true
  }

  tags = {
    environment = var.environment
    project     = "eshop"
  }
}

# Role assignment for AKS to pull from ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id                     = azurerm_kubernetes_cluster.eshop_aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                           = azurerm_container_registry.eshop_acr.id
  skip_service_principal_aad_check = true
}
