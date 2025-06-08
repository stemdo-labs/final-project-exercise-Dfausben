output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "vnet1_id" {
  value = azurerm_virtual_network.vnet1.id
}

output "vnet2_id" {
  value = azurerm_virtual_network.vnet2.id
}

output "vm1_private_ip" {
  value = azurerm_network_interface.nic1.private_ip_address
}

output "aks_cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "vm1_public_ip" {
  value = azurerm_public_ip.vm1_public_ip.ip_address
}
