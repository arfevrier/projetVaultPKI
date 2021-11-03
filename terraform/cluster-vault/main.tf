provider "vault" {
    address = "https://vault.4as:8200/"
    skip_tls_verify = true
    # Token: export VAULT_TOKEN="xxxx"
}

resource "vault_ldap_auth_backend" "ldap" {
    path        = "ldap"
    url         = "ldap://192.168.100.22"
    userdn      = "CN=Users,DC=INSA,DC=4AS"
    userattr    = "sAMAccountName"
    binddn      = "CN=Vault,CN=Users,DC=INSA,DC=4AS"
    bindpass    = file("../../ssl/password.key")
    groupdn     = "CN=Users,DC=INSA,DC=4AS"
    groupfilter = "(&(objectClass=person)(sAMAccountName={{.Username}}))"
    groupattr   = "memberOf"
    upndomain   = "INSA.4AS"    
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

resource "vault_policy" "ssh-4as-full-access" {
  name = "ssh-4as-full-access"
  policy = <<EOT
path "ssh-4as/sign/admin" {
  capabilities = ["update"]
}
EOT
}

resource "vault_pki_secret_backend" "ca-4as-cert" {
  path        = "ca-4as-cert"
}

resource "vault_pki_secret_backend_config_ca" "ca-4as-cert-ca" {
  backend = vault_pki_secret_backend.ca-4as-cert.path
  pem_bundle = file("../../ssl/vault.bundle.pem.key")
}

resource "vault_pki_secret_backend_role" "role" {
  backend          = vault_pki_secret_backend.ca-4as-cert.path
  name             = "domain_4as"
  ttl              = 1314000
  allowed_domains  = ["4as"]
  allow_subdomains = true
}

resource "vault_policy" "domain-4as-sign" {
  name = "domain-4as-sign"
  policy = <<EOT
path "ca-4as-cert/issue/domain_4as" {
  capabilities = ["update"]
}
path "ca-4as-cert/roles" {
  capabilities = ["list"]
}
EOT
}

resource "vault_ldap_auth_backend_group" "group" {
    groupname = "Etudiant"
    policies  = ["domain-4as-sign", "ssh-4as-full-access"]
    backend   = vault_ldap_auth_backend.ldap.path
}