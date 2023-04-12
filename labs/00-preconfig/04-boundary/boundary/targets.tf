
resource "boundary_target" "red" {
  name         = "k8s"
  description  = "local k8s"
  type         = "tcp"
  default_port = "443"
  scope_id     = boundary_scope.project.id
  host_source_ids = [
    boundary_host_set_static.kubernetes_api.id
  ]
  
  brokered_credential_source_ids = [
    boundary_credential_library_vault.red.id
  ]
}

