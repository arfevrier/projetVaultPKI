
## Setting up

> ansible-playbook -i inventory.yml --verify-password-file .password.txt

### After setup

Once the playbook totally played
##### On vault.trusted.toudherebarry.com
  - vault operator init > initial
  - Do the unseal phase with vault unseal "unseal-key" three times
  - Do the login phase: vault login "root-token"
  - `vault secrets enable transit`
  - `vault write -f transit/keys/autounseal`
  - 
  ````  
	  tee autounseal.hcl <<EOF
          path "transit/encrypt/autounseal" {
            capabilities = [ "update" ]
          }
          path "transit/decrypt/autounseal" {
          capabilities = [ "update" ]
          }
          EOF


  - `vault policy write autounseal autounseal.hcl`
  - `vault token create -policy="autounseal"`
> Use the token from here to configure the vault cluster server you want to use as active

In the transit configuration set token="token"

#### On vault server active
`VAULT_ADDR=http://127.0.0.1:8100 vault operator init > initial`
> initial will hold recovery keys

At this point you have a fully functionnal vault HA cluster with two consul backends and two vault servers provided with auto unseal on cluster restart
###** Change inventory hosts to suit your requirements **###

