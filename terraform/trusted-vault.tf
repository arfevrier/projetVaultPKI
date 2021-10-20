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
  default_lease_ttl_seconds = 3600
  max_lease_ttl_seconds     = 86400
}

resource "vault_transit_secret_backend_key" "key" {
  backend = vault_mount.transit.path
  name    = "autounseal"
}

resource "vault_policy" "autounseal-policy" {
  name = "ssh-4as-full-access"
  policy = <<EOT
path "transit/encrypt/autounseal" {
    capabilities = [ "update" ]
}
path "transit/decrypt/autounseal" {
    capabilities = [ "update" ]
}
EOT
}

resource "vault_mount" "ssh-4as" {
    type = "ssh"
    path = "ssh-4as"

    # Accès pour 4h par défaut, jusqu'à 12h.
    default_lease_ttl_seconds = "14400"  # 4h
    max_lease_ttl_seconds     = "43200" # 1w
}

resource "vault_ssh_secret_backend_ca" "ssh-4as-ca" {
    backend = vault_mount.ssh-4as.path
    generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "ssh-4as-admin" {
    name     = "admin"
    backend  = vault_mount.ssh-4as.path
    key_type = "ca"
    algorithm_signer = "rsa-sha2-256"

    allow_user_certificates = true
    default_user = "root"
    allowed_users = "*"
    default_extensions = {
        permit-pty = ""
        permit-port-forwarding = ""
    }
}

resource "vault_auth_backend" "userpass-4as" {
  type = "userpass"
  path = "userpass"
}

resource "vault_policy" "ssh-4as-full-access" {
  name = "ssh-4as-full-access"
  policy = <<EOT
path "ssh-4as/sign/admin" {
  capabilities = ["update"]
}
EOT
}