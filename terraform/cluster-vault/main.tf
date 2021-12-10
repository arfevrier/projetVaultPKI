provider "vault" {
    address = "https://vault.4as:8200/"
    skip_tls_verify = true
    # Token: export VAULT_TOKEN="xxxx"
}

resource "vault_audit" "file" {
  type = "file"

  options = {
    file_path = "/var/lib/vault/vault_audit.log"
  }
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

resource "vault_ssh_secret_backend_role" "ssh-4as-reseau" {
    name     = "reseau"
    backend  = vault_mount.ssh-4as.path
    key_type = "ca"
    algorithm_signer = "rsa-sha2-256"

    allow_user_certificates = true
    default_user = "reseau"
    allowed_users = "reseau"
    default_extensions = {
        permit-pty = ""
        permit-port-forwarding = ""
    }
}

resource "vault_ssh_secret_backend_role" "ssh-4as-opsi" {
    name     = "opsi"
    backend  = vault_mount.ssh-4as.path
    key_type = "ca"
    algorithm_signer = "rsa-sha2-256"

    allow_user_certificates = true
    default_user = "opsi"
    allowed_users = "opsi"
    default_extensions = {
        permit-pty = ""
        permit-port-forwarding = ""
    }
}

resource "vault_policy" "ssh-4as-full-access" {
  name = "ssh-4as-full-access"
  policy = <<EOT
path "ssh-4as/sign/*" {
  capabilities = ["update"]
}
EOT
}

resource "vault_policy" "ssh-4as-opsi" {
  name = "ssh-4as-opsi"
  policy = <<EOT
path "ssh-4as/sign/opsi" {
  capabilities = ["update"]
}
EOT
}

resource "vault_policy" "ssh-4as-reseau" {
  name = "ssh-4as-reseau"
  policy = <<EOT
path "ssh-4as/sign/reseau" {
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
  ttl              = 30000000
  max_ttl          = 30000000
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

resource "vault_ldap_auth_backend_group" "group-etudiant" {
    groupname = "Etudiant"
    policies  = ["domain-4as-sign"]
    backend   = vault_ldap_auth_backend.ldap.path
}

resource "vault_ldap_auth_backend_group" "group-deploiement" {
    groupname = "deploiement"
    policies  = ["ssh-4as-opsi"]
    backend   = vault_ldap_auth_backend.ldap.path
}

resource "vault_ldap_auth_backend_group" "group-reseau" {
    groupname = "reseaux"
    policies  = ["ssh-4as-reseau"]
    backend   = vault_ldap_auth_backend.ldap.path
}

resource "vault_mount" "ssh-4as-host" {
    type = "ssh"
    path = "ssh-4as-host"

    # Accès pour 4h par défaut, jusqu'à 12h.
    default_lease_ttl_seconds = "14400"  # 4h
    max_lease_ttl_seconds     = "43200" # 1w
}

resource "vault_ssh_secret_backend_ca" "ssh-4as-host" {
    backend = vault_mount.ssh-4as-host.path
    generate_signing_key = true
}

resource "vault_ssh_secret_backend_role" "ssh-4as-host" {
    name     = "host-sign"
    backend  = vault_mount.ssh-4as-host.path
    key_type = "ca"
    algorithm_signer = "rsa-sha2-256"

    allow_host_certificates = true
    allowed_domains  = "4as"
    allow_subdomains = true
}

resource "vault_policy" "ssh-4as-host-full-access" {
  name = "ssh-4as-host-full-access"
  policy = <<EOT
path "ssh-4as-host/sign/*" {
  capabilities = ["update"]
}
EOT
}

resource "vault_auth_backend" "approle" {
  type = "approle"
}

resource "vault_approle_auth_backend_role" "ssh-4as-host-approle" {
  backend        = vault_auth_backend.approle.path
  role_name      = "ssh-4as-host-approle"
  bind_secret_id = false
  token_ttl      = 1200
  token_max_ttl  = 1800
  token_policies = ["ssh-4as-host-full-access"]
  token_bound_cidrs = ["192.168.100.0/24"]
  token_num_uses = 10
}

## Some secrets

resource "vault_mount" "secret-kube" {
  path        = "secret-kube"
  type        = "kv-v2"
}

resource "vault_generic_secret" "secret-kube-test" {
  path = "secret-kube/test"

  data_json = <<EOT
{
  "foo":   "bar",
  "pizza": "cheese"
}
EOT
}

resource "vault_policy" "secret-kube-read" {
  name = "secret-kube-read"
  policy = <<EOT
path "secret-kube/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "kube-4as" {
  backend                = vault_auth_backend.kubernetes.path
  kubernetes_host        = "https://192.168.100.208:6443"
  kubernetes_ca_cert     = "-----BEGIN CERTIFICATE-----\nMIIC/jCCAeagAwIBAgIBADANBgkqhkiG9w0BAQsFADAVMRMwEQYDVQQDEwprdWJl\ncm5ldGVzMB4XDTIxMTAyMTIxMDAwNVoXDTMxMTAxOTIxMDAwNVowFTETMBEGA1UE\nAxMKa3ViZXJuZXRlczCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMGk\nd0PAoaLVILh70n6GMpWfgDvpZcX8iK8EVskdgQUIFAU4U8C9SQ1aiWUVVTWRi7DO\ny8QnSgHKYPJW1IfnKyPsenn/o+4C2zBr/C7H8lLsL+ugtCmSUuuhp5Zlxye0Cjnb\ntc1iz0OOP1xOI/1wiB7xGVYgbHsoZGuxYZwQH7r29FXHuZpBPwrNCSOpVmiB/O7h\neTx0PIQf3u5XulC3PG4Stnnh6gKH1Fgw637gxwWGwVFEDJDZB4iSFkg5jIDSLnoF\nVtHW3fklEGEKa6IcuIy3WSQE0wpyNN4xTQnUmY229lKG9isUr1td53HckIAnAfDa\nXZi+Y8jPqR7JXwIR5vsCAwEAAaNZMFcwDgYDVR0PAQH/BAQDAgKkMA8GA1UdEwEB\n/wQFMAMBAf8wHQYDVR0OBBYEFG+OSaKxwOI10YbSdUzfaMWjFrC8MBUGA1UdEQQO\nMAyCCmt1YmVybmV0ZXMwDQYJKoZIhvcNAQELBQADggEBACXx5v38hO08bRliftzJ\nACRcqDhm7GesKrQXH9IrIuMv5p3Cngym225vDsrc5Et3tK8crDOE3k0phue5MnV8\nApSh2ErCz03+AzXhfifRs3sEzItPGJ88FTyIH9ikHKXoMwGFQFIuu3mMr9IowwGv\nZn11bM3b2ULiq4Of+1jNS5BaInGaBAU6iHLbnzapWfa23GJZzs+ACZJM9IU08ufq\nLFvxp6fL73ewb7c7N8vz2f6pmvFkZ61aH3jYeuuVInKSyHxt/geWbs6KYT5rkhzB\nmVL41zywe9atViz1BCOpZvKJlPgfYoZPSr13eXQ119M9l0xiSkqSnMkm2KpPMn76\nGLI=\n-----END CERTIFICATE-----"
  token_reviewer_jwt     = file("../../ssl/kubernetes.key")
  issuer                 = "https://kubernetes.default.svc.cluster.local"
  #disable_iss_validation = "true" //Kubernetes +v1.21 https://github.com/external-secrets/kubernetes-external-secrets/issues/721
}

resource "vault_kubernetes_auth_backend_role" "kube-4as" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = "kube-4as"
  bound_service_account_names      = ["default"]
  bound_service_account_namespaces = ["vault"]
  token_ttl                        = 3600
  token_policies                   = ["default", "secret-kube-read"]
}
