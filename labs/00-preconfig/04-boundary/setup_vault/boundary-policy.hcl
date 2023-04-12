path "auth/token/lookup-self" {
  capabilities = ["read"]
}

path "auth/token/renew-self" {
  capabilities = ["update"]
}

path "auth/token/revoke-self" {
  capabilities = ["update"]
}

path "sys/leases/renew" {
  capabilities = ["update"]
}

path "sys/leases/revoke" {
  capabilities = ["update"]
}

path "sys/capabilities-self" {
  capabilities = ["update"]
}

#Permissions to assume auto-managed-sa-and-role role 
#and update (aka generate) K8s tokens 
path "kubernetes/creds/auto-managed-sa-and-role" {
  capabilities = ["update"]
}

#Permissions to access Kubernetes CA certificate stored 
#in this path
path "secret/data/k8s-cluster" {
 capabilities = ["read"]
}
