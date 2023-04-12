resource "boundary_scope" "global" {
  global_scope = true
  name         = "global"
  scope_id     = "global"
}

resource "boundary_scope" "org" {
  scope_id    = boundary_scope.global.id
  name        = "primary"
  description = "Primary organization scope"
}

resource "boundary_scope" "project" {
  name                     = "k8s"
  description              = "k8s private endpoint project"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}


resource "boundary_credential_store_vault" "project" {
  name        = "vault"
  description = "My first Vault credential store!"
  address     = "${var.vault_hostname}"      # change to Vault address
  token       = file("${path.root}/boundary-token") # change to valid Vault token
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_library_vault" "red" {
  name                = "red"
  description         = "My second Vault credential library!"
  credential_store_id = boundary_credential_store_vault.project.id
  path                = "kubernetes/creds/auto-managed-sa-and-role" # change to Vault backend path
  http_method         = "POST"
  http_request_body   = <<EOT
{
  "kubernetes_namespace": "red-zero-trust"	
}
EOT
}

resource "boundary_credential_library_vault" "ca" {
  name                = "bar"
  description         = "My second Vault credential library!"
  credential_store_id = boundary_credential_store_vault.project.id
  path                = "secret/data/k8s-cluster" # change to Vault backend path
  http_method         = "GET"
}