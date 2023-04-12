
module "boundary" {
  source = "./boundary"
  addr   = "http://vcluster-user1-boundary.aws.sphinxgaia.jeromemasson.fr"
  vault_hostname  = "http://vcluster-user1-vault.aws.sphinxgaia.jeromemasson.fr"

}

output "boundary_auth_method_id" {
  value = module.boundary.boundary_auth_method_password
}

output "password" {
  value = module.boundary.password
  sensitive = true
}

output "boundary_connect_syntax" {
  value       = <<EOT

# https://learn.hashicorp.com/tutorials/boundary/oss-getting-started-connect?in=boundary/oss-getting-started

boundary authenticate password -login-name jmasson -auth-method-id ${module.boundary.boundary_auth_method_password}

EOT
  description = "Boundary Authenticate"
}
