resource "boundary_host_set_static" "kubernetes_api" {
  type            = "static"
  name            = "kubernetes"
  description     = "Host set for kubernetes api"
  host_catalog_id = boundary_host_catalog_static.kubernetes.id
  host_ids        = [boundary_host_static.kubernetes.id]
}

