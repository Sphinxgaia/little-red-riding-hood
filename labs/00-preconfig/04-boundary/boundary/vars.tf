variable "addr" {
  default = "http://127.0.0.1:9200"
}

variable "users" {
  type = set(string)
  default = [    
    "red",   
    "green"
  ]
}

variable "admins" {
  type = set(string)
  default = [
    "admin0"
  ]
}

variable "vault_hostname" {
  default = "http://vault.vault.svc:8200"
  type    = string
}