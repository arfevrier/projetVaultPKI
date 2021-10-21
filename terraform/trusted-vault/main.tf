provider "vault" {
    address = "https://192.168.100.6:8200/"
    skip_tls_verify = true
    # Token: export VAULT_TOKEN="xxxx"
}

resource "vault_audit" "file" {
  type = "file"

  options = {
    file_path = "/var/lib/vault/vault_audit.log"
  }
}

resource "vault_mount" "transit" {
  path                      = "transit"
  type                      = "transit"
}

resource "vault_transit_secret_backend_key" "autounseal" {
  backend = vault_mount.transit.path
  name    = "autounseal"
}

resource "vault_policy" "autounseal-policy" {
  name = "autounseal-policy"
  policy = <<EOT
path "transit/encrypt/autounseal" {
    capabilities = [ "update" ]
}
path "transit/decrypt/autounseal" {
    capabilities = [ "update" ]
}
EOT
}