
## Setting up

> ansible-playbook -i inventory.yml trusted.yml

##### On vault.trusted.toudherebarry.com
  - `VAULT_ADDR="http://127.0.0.1:8200" vault operator init > initial`
  - Do the unseal phase with `VAULT_ADDR="http://127.0.0.1:8200" vault operator unseal "unseal-key"` three times
  - Do the login phase: vault login "root-token"
  - `VAULT_ADDR="http://127.0.0.1:8200" vault audit enable file file_path=/var/lib/vault/vault_audit.log` ==> enabling audit logs
  - `VAULT_ADDR="http://127.0.0.1:8200" vault secrets enable transit`
  - `VAULT_ADDR="http://127.0.0.1:8200" vault write -f transit/keys/autounseal`
  - 
  ```  
	  tee autounseal.hcl <<EOF
          path "transit/encrypt/autounseal" {
            capabilities = [ "update" ]
          }
          path "transit/decrypt/autounseal" {
          capabilities = [ "update" ]
          }
          EOF

  ```
  - `VAULT_ADDR="http://127.0.0.1:8200" vault policy write autounseal autounseal.hcl`
  - `VAULT_ADDR="http://127.0.0.1:8200" vault token create -policy="autounseal"`
> Use the token from here to configure the vault cluster server you want to use as active

In the transit configuration set token="token"


> ansible-playbook -i inventory.yml trusted.yml


#### On vault server active
`VAULT_ADDR="http://127.0.0.1:8200" vault operator init > initial`
> initial will hold recovery keys

`VAULT_ADDR="http://127.0.0.1:8200" vault login` and then provide root token

At this point you have a fully functionnal vault HA cluster with raft as backends for two vault servers provided with auto unseal on cluster restart

### ⚠️ Change inventory hosts to suit your requirements

