# Data sources for existing resources
data "azurerm_resource_group" "main" {
  name = "eShopCleverRG"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = "eshopcleveraks"
  resource_group_name = data.azurerm_resource_group.main.name
}

# Chaos Studio Target for AKS Cluster
resource "azurerm_chaos_studio_target" "aks_target" {
  target_resource_id = data.azurerm_kubernetes_cluster.aks.id
  target_type        = "Microsoft-AzureKubernetesServiceChaosMesh"
  location           = "eastus"  # Match existing location
}

# Pod Failure Chaos Experiment  
resource "azurerm_chaos_studio_experiment" "pod_failure" {
  name                = "eshoppodfailure"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = "eastus"  # Match existing location
  
  identity {
    type = "SystemAssigned"
  }
  
  selectors {
    name                     = "e2068fab-b420-4022-af81-d0bff3963fa4"  # Use existing selector ID
    chaos_studio_target_ids  = [azurerm_chaos_studio_target.aks_target.id]
  }
  
  steps {
    name = "Step 1"  # Match existing
    branch {
      name = "Branch 1"  # Match existing
      actions {
        urn           = "urn:csci:microsoft:azureKubernetesServiceChaosMesh:podChaos/2.2"  # Match existing version
        action_type   = "continuous"
        duration      = "PT5M"  # Match existing
        selector_name = "e2068fab-b420-4022-af81-d0bff3963fa4"  # Use existing selector ID
        parameters = {
          jsonSpec = jsonencode({
            action = "pod-failure"
            mode = "one"
            duration = "60s"  # Match existing
            selector = {
              namespaces = ["eshop"]  # Match existing namespace
              labelSelectors = {
                "app" = "eshop-webmvc"  # Corrected to match actual pod labels
              }
            }
          })
        }
      }
    }
  }
}

# CPU Stress Chaos Experiment
resource "azurerm_chaos_studio_experiment" "cpu_stress" {
  name                = "eshopcpustress"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = "eastus"  # Match existing location
  
  identity {
    type = "SystemAssigned"
  }
  
  selectors {
    name                     = "4ee88cdb-239f-4322-aff1-1763de57504d"  # Use existing selector ID
    chaos_studio_target_ids  = [azurerm_chaos_studio_target.aks_target.id]
  }
  
  steps {
    name = "Step 1"  # Match existing
    branch {
      name = "Branch 1"  # Match existing
      actions {
        urn           = "urn:csci:microsoft:azureKubernetesServiceChaosMesh:stressChaos/2.2"  # Match existing version
        action_type   = "continuous"
        duration      = "PT5M"
        selector_name = "4ee88cdb-239f-4322-aff1-1763de57504d"  # Use existing selector ID
        parameters = {
          jsonSpec = jsonencode({
            mode = "one"
            duration = "300s"
            selector = {
              namespaces = ["eshop"]  # Match existing namespace
              labelSelectors = {
                "app" = "eshop-webmvc"  # Corrected to match actual pod labels
              }
            }
            stressors = {
              cpu = {
                workers = 2
                load = 80
              }
            }
          })
        }
      }
    }
  }
}

# Network Delay Chaos Experiment
resource "azurerm_chaos_studio_experiment" "network_delay" {
  name                = "eshopnetworkdelay"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = "eastus"  # Match existing location
  
  identity {
    type = "SystemAssigned"
  }
  
  selectors {
    name                     = "4ade6d26-d151-48bb-91a7-ce5cb31a3356"  # Use existing selector ID
    chaos_studio_target_ids  = [azurerm_chaos_studio_target.aks_target.id]
  }
  
  steps {
    name = "Step 1"  # Match existing
    branch {
      name = "Branch 1"  # Match existing
      actions {
        urn           = "urn:csci:microsoft:azureKubernetesServiceChaosMesh:networkChaos/2.2"  # Match existing version
        action_type   = "continuous"
        duration      = "PT10M"
        selector_name = "4ade6d26-d151-48bb-91a7-ce5cb31a3356"  # Use existing selector ID
        parameters = {
          jsonSpec = jsonencode({
            action = "delay"
            mode = "one"
            duration = "180s"
            selector = {
              namespaces = ["eshop"]  # Match existing namespace
              labelSelectors = {
                "app" = "eshop-webmvc"  # Corrected to match actual pod labels
              }
            }
            delay = {
              latency = "200ms"
              correlation = "0"
              jitter = "10ms"
            }
          })
        }
      }
    }
  }
}

# Memory Stress Chaos Experiment
resource "azurerm_chaos_studio_experiment" "memory_stress" {
  name                = "eshopmemorystress"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = "eastus"  # Match existing location
  
  identity {
    type = "SystemAssigned"
  }
  
  selectors {
    name                     = "33f82c74-6ab5-43a6-8367-7908b4e36da8"  # Use existing selector ID
    chaos_studio_target_ids  = [azurerm_chaos_studio_target.aks_target.id]
  }
  
  steps {
    name = "Step 1"  # Match existing
    branch {
      name = "Branch 1"  # Match existing
      actions {
        urn           = "urn:csci:microsoft:azureKubernetesServiceChaosMesh:stressChaos/2.2"  # Match existing version
        action_type   = "continuous"
        duration      = "PT10M"
        selector_name = "33f82c74-6ab5-43a6-8367-7908b4e36da8"  # Use existing selector ID
        parameters = {
          jsonSpec = jsonencode({
            mode = "one"
            duration = "240s"
            selector = {
              namespaces = ["eshop"]  # Match existing namespace
              labelSelectors = {
                "app" = "eshop-publicapi"  # Corrected to match actual pod labels
              }
            }
            stressors = {
              memory = {
                workers = 1
                size = "512MB"
              }
            }
          })
        }
      }
    }
  }
}
