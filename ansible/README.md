## Setting up

> ansible-playbook -i inventory.yml 1-trusted-vault.yml

##### On Trusted Vault (192.168.100.6)
  - `export VAULT_SKIP_VERIFY=1`
  - `vault operator init > initial`
  - Do the unseal phase with `vault operator unseal "unseal-key"` three times
  - `vault token create -policy="autounseal-policy"`

Put the token in a file .secret.yml with "token" key.

> ansible-playbook -i inventory.yml 2-cluster-vault.yml

#### On Cluster Vault (192.168.100.3-4)
`VAULT_ADDR="http://127.0.0.1:8200" vault operator init > initial`
> initial will hold recovery keys

`VAULT_ADDR="http://127.0.0.1:8200" vault login` and then provide root token

At this point you have a fully functionnal vault HA cluster with raft as backends for two vault servers provided with auto unseal on cluster restart

### ⚠️ Change inventory hosts to suit your requirements

