resource "azurerm_resource_group" "esic" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "esiclabacr"
  resource_group_name = azurerm_resource_group.esic.name
  location            = azurerm_resource_group.esic.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-aks"
  location            = azurerm_resource_group.esic.location
  resource_group_name = azurerm_resource_group.esic.name
  dns_prefix          = "esiclab"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_vm_size
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aks_acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}